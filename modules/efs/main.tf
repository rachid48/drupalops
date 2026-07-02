# EFS File System - shared storage for Drupal files across all ASG instances
resource "aws_efs_file_system" "drupal" {
  creation_token = "drupal-efs"
  encrypted      = true

  tags = {
    Name      = "drupal-efs"
    Project   = "DrupalOps"
    ManagedBy = "Terraform"
  }
}

# Security Group for EFS - allows NFS traffic from EC2 instances only
resource "aws_security_group" "efs" {
  name        = "efs-sg"
  description = "Allow NFS traffic from web instances only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.web_sg_id]
    description     = "Allow NFS from web EC2 instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name      = "efs-sg"
    Project   = "DrupalOps"
    ManagedBy = "Terraform"
  }
}

# EFS Mount Target - AZ 1
resource "aws_efs_mount_target" "az1" {
  file_system_id  = aws_efs_file_system.drupal.id
  subnet_id       = var.subnet_ids[0]
  security_groups = [aws_security_group.efs.id]
}

# EFS Mount Target - AZ 2
resource "aws_efs_mount_target" "az2" {
  file_system_id  = aws_efs_file_system.drupal.id
  subnet_id       = var.subnet_ids[1]
  security_groups = [aws_security_group.efs.id]
}
