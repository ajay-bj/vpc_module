resource "aws_iam_role" "iam_role" {
  name               = "${var.environment}-${data.aws_region.current.name}-${var.project}-${var.application_name}-role"
  assume_role_policy = var.trust_relationship_policy
  tags = {
    Project      = var.project
    Environment  = var.environment
    Owner        = var.owner
    map-migrated = "migWFWCRXIEQA"
    CostCenter   = var.owner
  }
}

resource "aws_iam_policy" "iam_policy" {
  name   = "${var.environment}-${data.aws_region.current.name}-${var.project}-${var.application_name}-policy"
  policy = var.policy_json
  tags = {
    Project      = var.project
    Environment  = var.environment
    Owner        = var.owner
    map-migrated = "migWFWCRXIEQA"
    CostCenter   = var.owner
  }
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "managed_policy_attachment" {
  count      = length(var.managed_policy_arns)
  role       = aws_iam_role.iam_role.name
  policy_arn = var.managed_policy_arns[count.index]
}