data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "kms_key_id" {
  name = "/terraform/${var.project}/${var.environment}/kms/keyarn"
}

data "aws_iam_policy_document" "sns-topic-policy" {
  statement {
    sid    = "DefaultStatementID"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [aws_sns_topic.sns_topic.arn]
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
  dynamic "statement" {
    for_each = var.topic_policy_statements
    content {
      sid         = try(statement.value.sid, statement.key)
      actions     = try(statement.value.actions, null)
      effect      = try(statement.value.effect, null)
      resources     = try(statement.value.resources, [aws_sns_topic.sns_topic.arn])
      dynamic "principals" {
        for_each = try(statement.value.principals, [])
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }
      dynamic "condition" {
        for_each = try(statement.value.conditions, [])
        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}