resource "aws_s3_bucket" "cdn_bucket" {
  bucket = "${var.environment}-${var.project}-${var.application_name}-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cdn_bucket" {
  bucket = aws_s3_bucket.cdn_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_ssm_parameter.kms_key_id.value
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cdn_bucket" {
  bucket = aws_s3_bucket.cdn_bucket.id

  rule {
    id = "PurgeNoncurrentVersionAfter90Days"
    filter {
      prefix = ""
    }
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning_cdn_bucket" {
  bucket = aws_s3_bucket.cdn_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "cdn_bucket" {
  bucket = aws_s3_bucket.cdn_bucket.id

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET"]
    allowed_origins = var.s3_allowed_origins
    max_age_seconds = 3000
  }
}

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket_policy" "cdn_bucket_policy" {
  bucket = aws_s3_bucket.cdn_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          CanonicalUser = data.aws_canonical_user_id.current.id
          Service       = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.cdn_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn_distribution.arn
          }
        }
      },
      {
        Sid       = "DenyUnsecuredTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "${aws_s3_bucket.cdn_bucket.arn}/*"
        Condition = {
          Bool = { "aws:SecureTransport" = false }
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "cdn_distribution" {
  # Aliases
  aliases    = var.aliases
  web_acl_id = var.web_acl_id != "" ? var.web_acl_id : (var.environment == "prd" || var.environment == "uat" ? aws_wafv2_web_acl.waf_web_acl[0].arn : null)
  enabled    = true
  # Default cache behavior
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    default_ttl            = 300
    min_ttl                = 0
    max_ttl                = 300
    target_origin_id       = "S3BucketOrigin1"
    smooth_streaming       = false
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
    response_headers_policy_id = data.aws_ssm_parameter.response_headers_policy_id.value
  }


  # Cache behaviors
  ordered_cache_behavior {
    path_pattern           = "*.html"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    default_ttl            = 300
    max_ttl                = 300
    min_ttl                = 0
    smooth_streaming       = false
    target_origin_id       = "S3BucketOrigin1"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    response_headers_policy_id = data.aws_ssm_parameter.response_headers_policy_id.value
  }


  price_class = "PriceClass_200"

  # Default root object
  default_root_object = var.default_root_object

  # Custom error responses
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }
  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/unauthorized-page.html"
    error_caching_min_ttl = 0
  }


  # Viewer certificate
  viewer_certificate {
    acm_certificate_arn      = data.aws_ssm_parameter.ssl_acm_certificate.value
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  # Origins
  origin {
    domain_name              = aws_s3_bucket.cdn_bucket.bucket_regional_domain_name
    origin_id                = "S3BucketOrigin1"
    origin_access_control_id = aws_cloudfront_origin_access_control.cdn_origin_access_control.id
  }

  logging_config {
    bucket          = data.aws_ssm_parameter.s3_log_bucket.value
    prefix          = "${var.environment}-${var.project}-${var.application_name}-${data.aws_region.current.name}-cdn"
    include_cookies = false
  }


  # Tags
  tags = merge({ S3Origin = aws_s3_bucket.cdn_bucket.bucket_regional_domain_name }, local.common_tags)
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = var.restrict_location
    }
  }
}

resource "aws_wafv2_web_acl" "waf_web_acl" {
  count       = var.environment == "prd" || var.environment == "uat" ? 1 : 0
  provider    = aws.waf
  name        = "${var.environment}-${var.project}-${var.application_name}-${data.aws_region.current.name}-waf-web-acl"
  description = "WAF Web ACL for ${var.environment} ${var.project} ${var.application_name}"
  scope       = "CLOUDFRONT"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-${var.project}-${var.application_name}-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "TrustedIps"
    priority = 0
    override_action {
      none {}
    }
    statement {
      rule_group_reference_statement {
        arn = data.aws_ssm_parameter.trusted_ips_arn.value
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "TrustedIps"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-${var.project}-${var.application_name}-ipreputationlist-waf"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-${var.project}-${var.application_name}-knownbadinput-waf"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-${var.project}-${var.application_name}-${data.aws_region.current.name}-sqlingestion-waf"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 4
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-${var.project}-${var.application_name}-commonrule-waf"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesBotControlRuleSet"
    priority = 5
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesBotControlRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-${var.project}-${var.application_name}-botcontrol-waf"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAdminProtectionRuleSet"
    priority = 6
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAdminProtectionRuleSet"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-${var.project}-${var.application_name}-adminprotection-waf"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 7
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAnonymousIpList"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-${var.project}-${var.application_name}-anonymousiplist-waf"
      sampled_requests_enabled   = true
    }
  }
  tags = local.common_tags
}

resource "aws_ssm_parameter" "web_acl_arn" {
  count       = var.environment == "prd" || var.environment == "uat" ? 1 : 0
  name        = "/terraform/${var.project}/${var.application_name}/${var.environment}/waf/webacl"
  value       = aws_wafv2_web_acl.waf_web_acl[0].arn
  description = "Webacl arn for cloudfront distribution of the project"
  type        = "String"
}

resource "aws_wafv2_web_acl_logging_configuration" "web_acl_logging" {
  count                   = var.environment == "prd" || var.environment == "uat" ? 1 : 0
  provider                = aws.waf
  log_destination_configs = ["${data.aws_ssm_parameter.waf_log_bucket.value}"]
  resource_arn            = aws_wafv2_web_acl.waf_web_acl[0].arn

  logging_filter {
    default_behavior = "DROP"

    filter {
      behavior = "KEEP"
      condition {
        action_condition {
          action = "BLOCK"
        }
      }
      condition {
        action_condition {
          action = "ALLOW"
        }
      }
      condition {
        action_condition {
          action = "COUNT"
        }
      }
      requirement = "MEETS_ANY"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "cdn_origin_access_control" {
  name                              = "${var.environment}-${var.project}-${var.application_name}-${data.aws_region.current.name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
