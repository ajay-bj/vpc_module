resource "aws_sns_topic" "sns_topic" {
  name              = "${var.environment}-${data.aws_region.current.name}-${var.project}-${var.application_name}-topic"
  kms_master_key_id = data.aws_ssm_parameter.kms_key_id.value
  tags = {
    Project      = var.project
    Environment  = var.environment
    Owner        = var.owner
    map-migrated = "migWFWCRXIEQA"
    CostCenter   = var.owner
  }
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn    = aws_sns_topic.sns_topic.arn
  policy = data.aws_iam_policy_document.sns-topic-policy.json
}

resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  for_each  = var.subscriptions
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}


