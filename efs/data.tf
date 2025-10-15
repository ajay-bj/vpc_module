data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "kms_key_id" {
  name = "/terraform/common/${var.environment}/kms/keyarn"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/devops/vpc/vpc-id"
}