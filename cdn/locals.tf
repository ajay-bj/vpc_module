locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.owner
    Pod         = "${var.project}-web"
  }
}