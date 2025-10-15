variable "project" {}

variable "environment" {}

variable "owner" {}

variable "kms_key_policy" {
  type        = string
  description = "IAM policy for the KMS key"
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
