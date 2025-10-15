variable "environment" {
  type    = string
  default = ""
}

variable "project" {
  type    = string
  default = ""
}

variable "owner" {
  type    = string
  default = ""
}

################################################################################
# File System
################################################################################

variable "availability_zone_name" {
  description = "The AWS Availability Zone in which to create the file system. Used to create a file system that uses One Zone storage classes"
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "The file system performance mode. Can be either `generalPurpose` or `maxIO`. Default is `generalPurpose`"
  type        = string
  default     = "generalPurpose"
}

variable "encrypted" {
  description = "If `true`, the disk will be encrypted"
  type        = bool
  default     = true
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Defaults to `bursting`. Valid values: `bursting`, `elastic`, and `provisioned`. When using `provisioned`, also set `provisioned_throughput_in_mibps`"
  type        = string
  default     = "bursting"
}

################################################################################
# Mount Target(s)
################################################################################

variable "subnet_ids" {
  default = []
}

################################################################################
# Security Group
################################################################################

variable "efs_cidr_blocks" {
  description = "List of CIDR blocks allowed to access EFS"
  type        = list(string)
  default     = []
}

################################################################################
# Access Point(s)
################################################################################

variable "access_point_configs" {
  description = "A map of access point definitions to create"
  type = map(object({
    name           = string
    uid            = number
    gid            = number
    permissions    = string
    root_directory = string
  }))
  default = {}
}

################################################################################
# Backup Policy
################################################################################

variable "create_backup_policy" {
  description = "Determines whether a backup policy is created"
  type        = bool
  default     = true
}

variable "enable_backup_policy" {
  description = "Determines whether a backup policy is `ENABLED` or `DISABLED`"
  type        = bool
  default     = true
}