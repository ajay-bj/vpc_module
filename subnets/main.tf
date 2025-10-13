resource "aws_subnet" "subnets" {
  count             = length(var.subnets)
  vpc_id            = var.vpc_id
  cidr_block        = element(var.subnets, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.name}-subnet-az${count.index + 1}"
    Project = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_network_acl" "nacl" {
  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.subnets.*.id

  tags = {
      Name = "${var.name}-nacl"
      Provisioned = "terraform"
  }
}

resource "aws_network_acl_rule" "inbound" {
  count          = length(var.nacl_inbound)
  network_acl_id = aws_network_acl.nacl.id
  rule_number    = lookup(element(var.nacl_inbound, count.index), "rule_no", "")
  egress         = false
  protocol       = lookup(element(var.nacl_inbound, count.index), "protocol", "")
  rule_action    = lookup(element(var.nacl_inbound, count.index), "action", "")
  cidr_block     = lookup(element(var.nacl_inbound, count.index), "cidr_block", "")
  from_port      = lookup(element(var.nacl_inbound, count.index), "fport", "")
  to_port        = lookup(element(var.nacl_inbound, count.index), "tport", "")
}

resource "aws_network_acl_rule" "outbound" {
  count          = length(var.nacl_outbound)
  network_acl_id = aws_network_acl.nacl.id
  rule_number    = lookup(element(var.nacl_outbound, count.index), "rule_no", "")
  egress         = true
  protocol       = lookup(element(var.nacl_outbound, count.index), "protocol", "")
  rule_action    = lookup(element(var.nacl_outbound, count.index), "action", "")
  cidr_block     = lookup(element(var.nacl_outbound, count.index), "cidr_block", "")
  from_port      = lookup(element(var.nacl_outbound, count.index), "fport", "")
  to_port        = lookup(element(var.nacl_outbound, count.index), "tport", "")
}