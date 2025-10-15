resource "aws_kms_key" "kms_key" {
  description         = "${var.project} encryption KMS key"
  enable_key_rotation = true

  policy = var.kms_key_policy != null ? var.kms_key_policy :<<EOT
{
  "Version": "2012-10-17",
  "Id": "${var.environment}-${var.project}-kms-key-policy",
  "Statement": [
    {
      "Sid": "AllowKeyManagementByAccount",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOT
  tags = merge(var.tags, { Pod = var.project, Owner = var.owner, EnvType = var.environment, CostCenter  = var.owner})
}

resource "aws_kms_alias" "kms_key" {
  name          = "alias/${var.environment}-${data.aws_region.current.name}-${var.project}-key"
  target_key_id = aws_kms_key.kms_key.id
}

resource "aws_ssm_parameter" "kms_key" {
  name  = "/terraform/${var.project}/${var.environment}/kms/keyarn"
  value = aws_kms_key.kms_key.arn
  type  = "String"
}
