resource "aws_ec2_transit_gateway_vpc_attachment" "tgw" {
  count              = var.tgw_required ? 1 : 0
  subnet_ids         = [for x, y in lookup(lookup(module.subnets, "transitgateway", null), "subnets", null) : y]
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.main.id

  tags = {
    Name        = "${var.account_env}-${var.project_name}-transit-gateway-attachment"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "confluent_tgw" {
  count              = var.confluent_tgw_required ? 1 : 0
  subnet_ids         = [for x, y in lookup(lookup(module.subnets, "transitgateway", null), "subnets", null) : y]
  transit_gateway_id = var.confluent_tgw_id
  vpc_id             = aws_vpc.main.id

  tags = {
    Name        = "${var.account_env}-${var.project_name}-confluent-transit-gateway-attachment"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}