data "aws_ssm_parameter" "trusted_ips_arn" {
  name  = "/terraform/common/web/waf/trustedip/arn"
}
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "kms_key_id" {
  name = "/terraform/common/web/${var.environment}/kms"
}

data "aws_ssm_parameter" "ssl_acm_certificate" {
  name = "/terraform/devops/acm/us-east-1/yubi-domain"
}

data "aws_ssm_parameter" "response_headers_policy_id" {
  name = "/terraform/${var.environment}/devops/cloudfront/csp/id"
}

data "aws_ssm_parameter" "s3_log_bucket" {
  name = "/terraform/devops/${var.environment}/s3-log-bucket"
}

data "aws_ssm_parameter" "waf_log_bucket" {
  name  = "/terraform/devops/${var.environment}/waf-log-bucket"
}

