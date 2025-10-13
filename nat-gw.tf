resource "aws_eip" "ngw" {
  count  = length([for x, y in lookup(lookup(module.subnets, "public", null), "subnets", null) : y])
  domain = "vpc"
  tags = {
    Name        = "${var.account_env}-${var.project_name}-nat-gateway-az${count.index + 1}"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_nat_gateway" "ngw" {
  count         = length([for x, y in lookup(lookup(module.subnets, "public", null), "subnets", null) : y])
  allocation_id = element(aws_eip.ngw.*.id, count.index)
  subnet_id     = element([for x, y in lookup(lookup(module.subnets, "public", null), "subnets", null) : y], count.index)

  tags = {
    Name        = "${var.account_env}-${var.project_name}-nat-gateway-az${count.index + 1}"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}