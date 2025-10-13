resource "aws_route_table" "igw-rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.account_env}-${var.project_name}-igw-route"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_route_table" "firewall-rt" {
  count = var.firewall_required ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.account_env}-${var.project_name}-firewall-route"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_route_table" "public-rt" {
  count  = 3
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.account_env}-${var.project_name}-public-route-az${count.index + 1}"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_route_table" "private-rt" {
  count  = 3
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.account_env}-${var.project_name}-private-route-az${count.index + 1}"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_route_table" "tgw-rt" {
  count  = var.tgw_required ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.account_env}-${var.project_name}-tgw-route"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_route_table_association" "igw-rt-assoc" {
  gateway_id     = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.igw-rt.id
}

resource "aws_route_table_association" "public-rt-assoc" {
  count          = length([for x, y in lookup(lookup(module.subnets, "public", null), "subnets", null) : y])
  subnet_id      = element([for x, y in lookup(lookup(module.subnets, "public", null), "subnets", null) : y], count.index)
  route_table_id = element(aws_route_table.public-rt.*.id, count.index)
}

resource "aws_route_table_association" "private-lb-rt-assoc" {
  count          = length([for x, y in lookup(lookup(module.subnets, "private_load_balancer", null), "subnets", null) : y])
  subnet_id      = element([for x, y in lookup(lookup(module.subnets, "private_load_balancer", null), "subnets", null) : y], count.index)
  route_table_id = element(aws_route_table.private-rt.*.id, count.index)
}

resource "aws_route_table_association" "private-apps-rt-assoc" {
  count          = length([for x, y in lookup(lookup(module.subnets, "private_app_resources", null), "subnets", null) : y])
  subnet_id      = element([for x, y in lookup(lookup(module.subnets, "private_app_resources", null), "subnets", null) : y], count.index)
  route_table_id = element(aws_route_table.private-rt.*.id, count.index)
}
resource "aws_route_table_association" "private-db-rt-assoc" {
  count          = length([for x, y in lookup(lookup(module.subnets, "private_database", null), "subnets", null) : y])
  subnet_id      = element([for x, y in lookup(lookup(module.subnets, "private_database", null), "subnets", null) : y], count.index)
  route_table_id = element(aws_route_table.private-rt.*.id, count.index)
}

resource "aws_route_table_association" "management-rt-assoc" {
  count          = length([for x, y in lookup(lookup(module.subnets, "private_management", null), "subnets", null) : y])
  subnet_id      = element([for x, y in lookup(lookup(module.subnets, "private_management", null), "subnets", null) : y], count.index)
  route_table_id = element(aws_route_table.private-rt.*.id, count.index)
}

resource "aws_route_table_association" "tgw-rt-assoc" {
  count          = var.tgw_required ? length([for x, y in lookup(lookup(module.subnets, "transitgateway", null), "subnets", null) : y]) : 0
  subnet_id      = element([for x, y in lookup(lookup(module.subnets, "transitgateway", null), "subnets", null) : y], count.index)
  route_table_id = element(aws_route_table.tgw-rt.*.id, count.index)
}

resource "aws_route_table_association" "firewall-rt-assoc" {
  count          = var.firewall_required ? length([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y]) : 0
  subnet_id      = element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], count.index)
  route_table_id = aws_route_table.firewall-rt[0].id
}

resource "aws_route" "internet-gateway-route-to-firewall-subnets" {
  count                  = var.firewall_required ? 1 : 0
  route_table_id         = aws_route_table.firewall-rt[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "firewall-route-to-public-internet" {
  count                  = var.firewall_required ? length([for x, y in lookup(lookup(module.subnets, "public", null), "subnets", null) : y]) : 0
  route_table_id         = element(aws_route_table.public-rt.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], count.index)], 0)
}

resource "aws_route" "nat-gateway-route-to-private-subnets" {
  count                  = length(aws_route_table.private-rt.*.id)
  route_table_id         = element(aws_route_table.private-rt.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.ngw.*.id, count.index)
}

resource "aws_route" "fw-route-to-public-subnet-from-internet" {
  count                  = var.firewall_required ? length([for x, y in lookup(lookup(module.subnets, "public", null), "subnets", null) : y]) : 0
  route_table_id         = aws_route_table.igw-rt.id
  destination_cidr_block = element([for x, y in lookup(lookup(module.subnets, "public", null), "subnets_cidr", null) : y], count.index)
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], count.index)], 0)
}

resource "aws_route" "tw-route" {
  for_each               = var.tgw_required ? {} : {}
  route_table_id         = each.value[0]
  destination_cidr_block = each.value[1]
  transit_gateway_id     = var.tgw_id
  depends_on             = [aws_route_table.tgw-rt]
}

##route to global protect vpn , dso from private subnets via firewall
resource "aws_route" "private-route-to-gp-vpn" {
  count                  = var.gp_conn_required && var.firewall_required ? length(aws_route_table.private-rt.*.id) : 0
  route_table_id         = element(aws_route_table.private-rt.*.id, count.index)
  destination_cidr_block = var.gp_cidr
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], count.index)], 0)
}

resource "aws_route" "private-route-to-dso-vpc" {
  count                  = var.dso_vpc_conn_required && var.firewall_required ? length(aws_route_table.private-rt.*.id) : 0
  route_table_id         = element(aws_route_table.private-rt.*.id, count.index)
  destination_cidr_block = var.dso_vpc_cidr
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], count.index)], 0)
}
##route from private subnets to specified CIDRs via firewall
# resource "aws_route" "private-route-to-tgw-cidrs" {
#   count                  = var.tgw_required && var.firewall_required ? length(aws_route_table.private-rt.*.id) * length(var.tgw_route_cidrs) : 0
#   route_table_id         = element(aws_route_table.private-rt.*.id, floor(count.index / length(var.tgw_route_cidrs)))
#   destination_cidr_block = element(var.tgw_route_cidrs, count.index % length(var.tgw_route_cidrs))
#   vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], floor(count.index / length(var.tgw_route_cidrs)))], 0)
# }

##route from private subnets to specified CIDRs via firewall
resource "aws_route" "private-route-to-tgw-cidrs" {
  for_each = var.tgw_required && var.firewall_required ? {
    for pair in setproduct(aws_route_table.private-rt.*.id, var.tgw_route_cidrs) : "${pair[0]}-${pair[1]}" => {
      rt_id = pair[0]
      cidr  = pair[1]
    }
  } : {}

  route_table_id         = each.value.rt_id
  destination_cidr_block = each.value.cidr
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], index(aws_route_table.private-rt.*.id, each.value.rt_id))], 0)
}

##route to global protect vpn , dso from firewall subnet
resource "aws_route" "firewall-subnets-route-to-gp-vpn" {
  count                  = var.gp_conn_required && var.firewall_required ? 1: 0
  route_table_id         = aws_route_table.firewall-rt[0].id
  destination_cidr_block = var.gp_cidr
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "firewall-subnets-route-to-dso-vpc" {
  count                  = var.dso_vpc_conn_required && var.firewall_required ? 1: 0
  route_table_id         = aws_route_table.firewall-rt[0].id
  destination_cidr_block = var.dso_vpc_cidr
  transit_gateway_id     = var.tgw_id
}

##route from firewall subnet to tgw route cidrs
resource "aws_route" "firewall-subnets-route-to-tgw-cidrs" {
  count                  = var.tgw_required && var.firewall_required ? length(var.tgw_route_cidrs) : 0
  route_table_id         = aws_route_table.firewall-rt[0].id
  destination_cidr_block = element(var.tgw_route_cidrs, count.index)
  transit_gateway_id     = var.tgw_id
}

##route from firewall subnet to confluent tgw route cidrs
resource "aws_route" "firewall-subnets-route-to-confluent-tgw-cidrs" {
  count                  = var.confluent_tgw_required && var.firewall_required ? length(var.confluent_tgw_route_cidrs) : 0
  route_table_id         = aws_route_table.firewall-rt[0].id
  destination_cidr_block = element(var.confluent_tgw_route_cidrs, count.index)
  transit_gateway_id     = var.confluent_tgw_id
}

##route to global protect vpn , dso from tgw subnet
resource "aws_route" "tgw-subnets-route-to-gp-vpn" {
  count                  = var.gp_conn_required ? 1: 0
  route_table_id         = aws_route_table.tgw-rt[0].id
  destination_cidr_block = var.gp_cidr
  transit_gateway_id     = var.tgw_id
}

resource "aws_route" "tgw-subnets-route-to-dso-vpc" {
  count                  = var.dso_vpc_conn_required ? 1: 0
  route_table_id         = aws_route_table.tgw-rt[0].id
  destination_cidr_block = var.dso_vpc_cidr
  transit_gateway_id     = var.tgw_id
}

##route from tgw subnet to tgw route cidrs
resource "aws_route" "tgw-subnets-route-to-tgw-cidrs" {
  count                  = var.tgw_required ? length(var.tgw_route_cidrs) : 0
  route_table_id         = aws_route_table.tgw-rt[0].id
  destination_cidr_block = element(var.tgw_route_cidrs, count.index)
  transit_gateway_id     = var.tgw_id
}

##route from tgw subnet to confluent tgw route cidrs
resource "aws_route" "tgw-subnets-route-to-confluent-tgw-cidrs" {
  count                  = var.confluent_tgw_required ? length(var.confluent_tgw_route_cidrs) : 0
  route_table_id         = aws_route_table.tgw-rt[0].id
  destination_cidr_block = element(var.confluent_tgw_route_cidrs, count.index)
  transit_gateway_id     = var.confluent_tgw_id
}

#route from transitgateway to vpc private subnets(lb, app, db & mgt) via fw endpoints
resource "aws_route" "tgw-route-to-fw-endpoint-lb-tier" {
  count                  = var.tgw_required && var.firewall_required ? length([for x, y in lookup(lookup(module.subnets, "private_load_balancer", null), "subnets", null) : y]) : 0
  route_table_id         = aws_route_table.tgw-rt[0].id
  destination_cidr_block = element([for x, y in lookup(lookup(module.subnets, "private_load_balancer", null), "subnets_cidr", null) : y], count.index)
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], count.index)], 0)
}

resource "aws_route" "tgw-route-to-fw-endpoint-db-tier" {
  count                  = var.tgw_required && var.firewall_required ? length([for x, y in lookup(lookup(module.subnets, "private_database", null), "subnets", null) : y]) : 0
  route_table_id         = aws_route_table.tgw-rt[0].id
  destination_cidr_block = element([for x, y in lookup(lookup(module.subnets, "private_database", null), "subnets_cidr", null) : y], count.index)
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], count.index)], 0)
}

resource "aws_route" "tgw-route-to-fw-endpoint-mgt-tier" {
  count                  = var.tgw_required && var.firewall_required ? length([for x, y in lookup(lookup(module.subnets, "private_management", null), "subnets", null) : y]) : 0
  route_table_id         = aws_route_table.tgw-rt[0].id
  destination_cidr_block = element([for x, y in lookup(lookup(module.subnets, "private_management", null), "subnets_cidr", null) : y], count.index)
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], count.index)], 0)
}

resource "aws_route" "tgw-route-to-fw-endpoint-app-tier" {
  count                  = var.tgw_required && var.firewall_required ? length([for x, y in lookup(lookup(module.subnets, "private_app_resources", null), "subnets", null) : y]) : 0
  route_table_id         = aws_route_table.tgw-rt[0].id
  destination_cidr_block = element([for x, y in lookup(lookup(module.subnets, "private_app_resources", null), "subnets_cidr", null) : y], count.index)
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.firewall[0].firewall_status[0].sync_states) : ss.attachment[0].endpoint_id if ss.attachment[0].subnet_id == element([for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y], count.index)], 0)
}