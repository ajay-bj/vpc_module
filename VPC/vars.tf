variable "vpc_cidr" {
  description = "CIDR Range for the VPC Network"
}

variable "flowlog_bucket_arn" {
  description = "VPC flow logs S3 bucket"
}

variable "project_name" {
  description = "Project Name"
}

variable "env" {
  description = "Environment Name"
}

variable "account_env" {
  description = "account environment"
}

variable "azs" {
  description = "Availability zones to be used."
}

variable "subnets" {}

variable "tgw_required" {
  type    = bool
  default = false
}

variable "firewall_required" {
  type    = bool
  default = true
}

variable "tgw_id" {
  description = "Transit gateway ID"
}

variable "tgw_cidr" {
  description = "CIDR of transit gateway"
}

variable "fw_domain_allow_capacity" {
  type = string
}

variable "domain_allow" {
  type    = bool
  default = true
}

variable "fw_internal_ip_allow_capacity" {
  type = string
}

variable "internal_ip_allow" {
  type    = bool
  default = true
}

variable "fw_external_ip_allow_capacity" {
  type = string
}

variable "external_ip_allow" {
  type    = bool
  default = true
}

variable "fw_external_sftp_ip_allow_capacity" {
  type = string
}

variable "external_sftp_ip_allow" {
  type    = bool
  default = true
}

variable "fw_domain_allow_file_path" {
  type = string
}

variable "fw_suricata_internal_ip_file_path" {
  type = string
}

variable "fw_suricata_external_ip_file_path" {
  type = string
}

variable "fw_suricata_external_sftp_ip_file_path" {
  type = string
}

variable "gp_conn_required" {}
variable "gp_cidr" {}
variable "dso_vpc_conn_required" {}
variable "dso_vpc_cidr" {}
variable "fwroute_private_subnets_az1" {}
variable "fwroute_private_subnets_az2" {}
variable "fwroute_private_subnets_az3" {}

variable "tgw_route_cidrs" {
  description = "List of CIDR blocks to route through VPC endpoints"
  type        = list(string)
  default     = []
}

variable "fw_geo_block_capacity" {
  type = string
  default = ""
}

variable "fw_geo_block_required" {
  description = "Enable/disable geo blocking rule group"
  type        = bool
  default     = false
}

variable "fw_suricata_geo_block_file_path" {
  type = string
  default = ""
}

variable "confluent_tgw_required" {
  type        = bool
  default     = false
  description = "Whether Confluent Transit Gateway attachment is required"
}

variable "confluent_tgw_id" {
  type        = string
  description = "Confluent Transit Gateway ID"
  default     = ""
}

variable "confluent_tgw_route_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks to route through Confluent Transit Gateway"
  default     = []
}