data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "kms_key_id" {
  name = "/terraform/${var.project}/${var.environment}/kms/keyarn"
}

data "aws_ssm_parameter" "s3_log_bucket_name" {
  count = var.bucket_logging_enabled ? 1 : 0
  name = "/terraform/serversccesslog/s3-bucket-name"
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid    = "DenyUnsecuredTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}