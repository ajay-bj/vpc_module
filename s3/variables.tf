variable "project" {
  description = "Project name"
  type        = string
}

variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "owner" {
  description = "Owner of the resource"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_default_lifecycle_rule" {
  description = "Enable default lifecycle rule for moving noncurrent versions to Glacier after 90 days"
  type        = bool
  default     = true
}

variable "s3_bucket_policy" {
  type        = string
  description = "S3 bucket policy"
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules to configure"
  type = list(object({
    id     = string
    status = string
    prefix = optional(string)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })))
    expiration = optional(object({
      days = number
    }))
    noncurrent_version_transitions = optional(list(object({
      days          = number
      storage_class = string
    })))
    noncurrent_version_expiration = optional(object({
      days = number
    }))
  }))
  default = []
}

variable "bucket_logging_enabled" {
  type    = bool
  default = true
}
