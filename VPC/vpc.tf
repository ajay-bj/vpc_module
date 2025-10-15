resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.account_env}-${var.project_name}-vpc"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_flow_log" "main" {
  log_destination      = var.flowlog_bucket_arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  destination_options {
    file_format        = "plain-text"
    per_hour_partition = true
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}