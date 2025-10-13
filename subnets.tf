module "subnets" {
  for_each      = var.subnets
  source        = "./subnets"
  azs           = var.azs
  env           = var.env
  project_name  = var.project_name
  subnets       = each.value.subnets
  vpc_id        = aws_vpc.main.id
  name          = each.value.name
  nacl_inbound  = each.value.nacl_inbound
  nacl_outbound = each.value.nacl_outbound
}