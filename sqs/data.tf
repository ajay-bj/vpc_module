data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "kms_key_id" {
  name = "/terraform/${var.project}/${var.environment}/kms/keyarn"
}