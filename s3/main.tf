resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.environment}-${var.project}-${var.application_name}-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
  tags = merge(var.tags, { Pod = var.application_name, Owner = var.project, EnvType = var.environment, CostCenter  = var.owner, "map-migrated" = "migWFWCRXIEQA"})
}

resource "aws_s3_bucket_versioning" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_ssm_parameter.kms_key_id.value
    }
  }
}

resource "aws_s3_bucket_logging" "s3_bucket" {
  count = var.bucket_logging_enabled ? 1 : 0
  bucket        = aws_s3_bucket.s3_bucket.id
  target_bucket = data.aws_ssm_parameter.s3_log_bucket_name[0].value
  target_prefix = "${aws_s3_bucket.s3_bucket.id}/"
}


resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    id = "NoncurrentVersionToGlacierAfter90Days"
    filter {
      prefix = ""
    }
    status = "Enabled"
    noncurrent_version_transition {
      storage_class   = "GLACIER"
      noncurrent_days = 90
    }
  }
  // Additional rules
  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      filter {
        prefix = lookup(rule.value, "prefix", null)
      }

      dynamic "transition" {
        for_each = try(coalesce(rule.value.transitions, []), [])
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = try(rule.value.expiration, null) != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = try(coalesce(rule.value.noncurrent_version_transitions, []), [])
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_version_expiration, null) != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }
    }
  }
}

resource "aws_s3_bucket_policy" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = var.s3_bucket_policy != null ? var.s3_bucket_policy : data.aws_iam_policy_document.s3_bucket_policy.json
}

resource "aws_ssm_parameter" "logging_bucket_name" {
  count = var.bucket_logging_enabled ? 0 : 1
  name  = "/terraform/serversccesslog/s3-bucket-name"
  value = aws_s3_bucket.s3_bucket.id
  type  = "String"
}
