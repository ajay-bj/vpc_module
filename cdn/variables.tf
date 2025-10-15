

variable "default_root_object" {
  description = "Default root object for CloudFront distribution."
  default     = "index.html"
}

variable "environment" {
  description = "Select Environment."
}

variable "project" {
  description = "Select Project."
}

variable "application_name" {
  description = "Application name."
}

variable "s3_allowed_origins" {
  description = "s3 allowed origins"
}

variable "owner" {
  description = "Owner"
}

variable "aliases" {
  description = "Aliases name"
}

variable "web_acl_id" {
  default = ""
  description = "web_acl_id"
}

variable "restrict_location" {
  description = "List of locations for geo-restriction"
  type        = list(string)
  default     = ["IN", "AE"]
}


