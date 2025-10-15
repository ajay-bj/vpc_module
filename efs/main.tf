################################################################################
# File System
################################################################################

resource "aws_efs_file_system" "efs_file_system" {
  availability_zone_name = var.availability_zone_name
  performance_mode       = var.performance_mode
  encrypted              = var.encrypted
  kms_key_id             = data.aws_ssm_parameter.kms_key_id.value
  throughput_mode        = var.throughput_mode
  tags                   = merge(local.common_tags, { Name = "${var.environment}-${data.aws_region.current.name}-${var.project}-efs" })
}

################################################################################
# Mount Target(s)
################################################################################

resource "aws_efs_mount_target" "efs_mount_target" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.efs_file_system.id
  security_groups = ["${aws_security_group.security_group.id}"]
  subnet_id       = element(var.subnet_ids, count.index)
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "security_group" {
  name   = "${var.environment}-${data.aws_region.current.name}-${var.project}-efs-sg"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = var.efs_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${var.environment}-${data.aws_region.current.name}-${var.project}-efs-sg" })
}

################################################################################
# Access Point(s)
################################################################################

resource "aws_efs_access_point" "efs_access_point" {
  for_each = var.access_point_configs

  file_system_id = aws_efs_file_system.efs_file_system.id

  posix_user {
    uid = each.value.uid
    gid = each.value.gid
  }

  root_directory {
    path = each.value.root_directory

    creation_info {
      owner_uid   = each.value.uid
      owner_gid   = each.value.gid
      permissions = each.value.permissions
    }
  }

  tags = merge(local.common_tags, { Name = each.value.name })
}

################################################################################
# Backup Policy
################################################################################

resource "aws_efs_backup_policy" "this" {
  count = var.create_backup_policy ? 1 : 0

  file_system_id = aws_efs_file_system.efs_file_system.id

  backup_policy {
    status = var.enable_backup_policy ? "ENABLED" : "DISABLED"
  }
}