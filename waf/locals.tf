locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    CostCenter  = var.owner
  }
}