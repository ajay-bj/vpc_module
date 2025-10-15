variable "project" {}

variable "environment" {}

variable "owner" {}

variable "web_acl_name" {
  type        = string
  description = "Name for the WAFv2 Web ACL."
}

variable "web_acl_description" {
  description = "A description for the WAFv2 Web ACL."
  type        = string
  default     = "Web ACL created by Terraform."
}

variable "scope" {
  description = "The scope of the web ACL. Valid values are REGIONAL or CLOUDFRONT."
  type        = string
  default     = "REGIONAL"
}

variable "default_action" {
  type        = string
  description = "The action to perform if none of the rules contained in the WebACL match."
  default     = "allow"
}

variable "managed_rules" {
  type = list(object({
    name            = string
    priority        = number
    override_action = string
    vendor_name     = string
    version         = optional(string)
    rule_action_override = list(object({
      name          = string
      action_to_use = string
    }))
  }))
  description = "List of Managed WAF rules."
  default = [
    {
      name                 = "AWSManagedRulesAmazonIpReputationList",
      priority             = 0
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesKnownBadInputsRuleSet",
      priority             = 1
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesSQLiRuleSet",
      priority             = 2
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesCommonRuleSet",
      priority             = 3
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesBotControlRuleSet",
      priority             = 4
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesAdminProtectionRuleSet",
      priority             = 5
      override_action      = "none"
      vendor_name          = "AWS"
      rule_action_override = []
    }
  ]
}