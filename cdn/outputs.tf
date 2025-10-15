output "s3_bucket_name" {
  value = aws_s3_bucket.cdn_bucket.bucket
}

output "s3_bucket_domain_name" {
  value = aws_s3_bucket.cdn_bucket.bucket_domain_name
}

output "s3_regional_domain_name" {
  value = aws_s3_bucket.cdn_bucket.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cdn_distribution.id
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.cdn_distribution.domain_name
}

output "cloudfront_origin_access_conmtrol_id" {
  description = "CloudFront Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.cdn_origin_access_control.id
}
output "canonical_user_id" {
  value = data.aws_canonical_user_id.current.id
}