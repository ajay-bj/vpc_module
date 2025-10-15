resource "aws_sqs_queue" "sqs_queue" {
  name                              = "${var.environment}-${data.aws_region.current.name}-${var.project}-${var.application_name}-queue"
  delay_seconds                     = 0
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  kms_data_key_reuse_period_seconds = 300
  kms_master_key_id                 = data.aws_ssm_parameter.kms_key_id.value
  visibility_timeout_seconds        = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 10
  })
  tags = {
    Project      = var.project
    Environment  = var.environment
    Owner        = var.owner
    map-migrated = "migWFWCRXIEQA"
    CostCenter   = var.owner
  }
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                              = "${var.environment}-${data.aws_region.current.name}-${var.project}-${var.application_name}-dl-queue"
  delay_seconds                     = 0
  max_message_size                  = 262144
  message_retention_seconds         = 345600
  receive_wait_time_seconds         = 0
  kms_data_key_reuse_period_seconds = 300
  kms_master_key_id                 = data.aws_ssm_parameter.kms_key_id.value
  visibility_timeout_seconds        = 30
  tags = {
    Project      = var.project
    Environment  = var.environment
    Owner        = var.owner
    map-migrated = "migWFWCRXIEQA"
    CostCenter   = var.owner
  }
}
