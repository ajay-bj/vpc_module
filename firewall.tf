resource "aws_networkfirewall_rule_group" "domain_allow_stateful" {
  count = var.domain_allow && var.firewall_required ? 1: 0
  description = "Stateful domain allow firewall Rule"
  capacity    = var.fw_domain_allow_capacity
  name        = "${var.account_env}-${var.project_name}-domain-stateful-rule"
  type        = "STATEFUL"
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets = [
          for line in split("\n", file("${var.fw_domain_allow_file_path}")) : trim(line, " \r")
        ]
      }
    }
  }
  tags = {
    Name        = "${var.account_env}-${var.project_name}-stateful-domain-rule"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_networkfirewall_rule_group" "internal_ip_allow_stateful" {
  count = var.internal_ip_allow && var.firewall_required ? 1: 0
  description = "Rule group to whitelist internal ips"
  capacity    = var.fw_internal_ip_allow_capacity
  type        = "STATEFUL"
  name        = "${var.account_env}-${var.project_name}-internal-ip-stateful-rg"
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rules_source {
      rules_string = file("${var.fw_suricata_internal_ip_file_path}")
    }
  }
  tags = {
    Name        = "${var.account_env}-${var.project_name}-stateful-internal-rule"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_networkfirewall_rule_group" "external_ip_allow_stateful" {
  count = var.external_ip_allow && var.firewall_required ? 1: 0
  description = "Rule group to whitelist external ips"
  capacity    = var.fw_external_ip_allow_capacity
  type        = "STATEFUL"
  name        = "${var.account_env}-${var.project_name}-external-ip-stateful-rg"
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rules_source {
      rules_string = file("${var.fw_suricata_external_ip_file_path}")
    }
  }

  tags = {
    Name        = "${var.account_env}-${var.project_name}-stateful-external-rule"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_networkfirewall_rule_group" "external_sftp_ip_allow_stateful" {
  count = var.external_sftp_ip_allow && var.firewall_required ? 1: 0  
  description = "Rule group to whitelist external sftp ips"
  capacity    = var.fw_external_sftp_ip_allow_capacity
  type        = "STATEFUL"
  name        = "${var.account_env}-${var.project_name}-external-sftp-ip-stateful-rg"
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rules_source {
      rules_string = file("${var.fw_suricata_external_sftp_ip_file_path}")
    }
  }

  tags = {
    Name        = "${var.account_env}-${var.project_name}-stateful-external-sftp-rule"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_networkfirewall_rule_group" "geo_block_stateful" {
  count       = var.fw_geo_block_required && var.firewall_required ? 1 : 0
  description = "Rule group to block traffic from specific countries"
  capacity    = var.fw_geo_block_capacity
  type        = "STATEFUL"
  name        = "${var.account_env}-${var.project_name}-geo-block-stateful-rg"
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rules_source {
      rules_string = file("${var.fw_suricata_geo_block_file_path}")
    }
  }

  tags = {
    Name        = "${var.account_env}-${var.project_name}-stateful-geo-block-rule"
    CostCenter  = "shared-services"
    EnvType     = var.account_env
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_networkfirewall_firewall_policy" "network_firewall_policy" {
  count = var.firewall_required ? 1 : 0
  name = "${var.account_env}-${var.project_name}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_default_actions           = ["aws:drop_established","aws:alert_established"]
    stateful_engine_options {
      rule_order              = "STRICT_ORDER"
      stream_exception_policy = "REJECT"
    }

    dynamic "stateful_rule_group_reference" {
        for_each = var.fw_geo_block_required ? [1] : []
        content {
            resource_arn = aws_networkfirewall_rule_group.geo_block_stateful[0].arn
            priority     = 5
        }
    }
    #Conditionally generate the stateful rule group references
    dynamic "stateful_rule_group_reference" {
        for_each = var.domain_allow && var.firewall_required ? [1] : []
        content {
            resource_arn = aws_networkfirewall_rule_group.domain_allow_stateful[0].arn
            priority     = 10
        }
    }
    dynamic "stateful_rule_group_reference" {
         for_each = var.external_ip_allow && var.firewall_required ? [1] : []
         content {
             resource_arn = aws_networkfirewall_rule_group.external_ip_allow_stateful[0].arn
             priority     = 20
         }
     }
     dynamic "stateful_rule_group_reference" {
        for_each = var.internal_ip_allow && var.firewall_required ? [1] : []
        content {
            resource_arn = aws_networkfirewall_rule_group.internal_ip_allow_stateful[0].arn
            priority     = 30
        }
    }
     dynamic "stateful_rule_group_reference" {
        for_each = var.external_sftp_ip_allow && var.firewall_required ? [1] : []
        content {
            resource_arn = aws_networkfirewall_rule_group.external_sftp_ip_allow_stateful[0].arn
            priority     = 40
        }
    }
  }

  tags = {
    Name        = "${var.account_env}-${var.project_name}-firewall-policy"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_networkfirewall_firewall" "firewall" {
  count = var.firewall_required ? 1 : 0
  name                = "${var.account_env}-${var.project_name}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.network_firewall_policy[0].arn
  vpc_id              = aws_vpc.main.id
  # delete_protection   = true
  dynamic "subnet_mapping" {
    for_each = [for x, y in lookup(lookup(module.subnets, "firewall", null), "subnets", null) : y]
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = {
    Name        = "${var.account_env}-${var.project_name}-stateful-domain-rule"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}


resource "aws_cloudwatch_log_group" "alert_loggroup" {
  count = var.firewall_required ? 1 : 0
  name = "/aws/firewall/alertlog-group"

  tags = {
    Name        = "${var.account_env}-${var.project_name}-stateful-domain-rule"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "flow_loggroup" {
  count = var.firewall_required ? 1 : 0
  name = "/aws/firewall/flowlog-group"

  tags = {
    Name        = "${var.account_env}-${var.project_name}-stateful-domain-rule"
    Project     = var.project_name
    Provisioned = "terraform"
  }
}

resource "aws_networkfirewall_logging_configuration" "alert_logging" {
  count = var.firewall_required ? 1 : 0
  firewall_arn = aws_networkfirewall_firewall.firewall[0].arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        bucketName = "yubi-group-firewall-logs"
        prefix     = "yubi"
      }
      log_destination_type = "S3"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        bucketName = "yubi-group-firewall-logs"
        prefix     = "yubi"
      }
      log_destination_type = "S3"
      log_type             = "FLOW"
    }
  }
}