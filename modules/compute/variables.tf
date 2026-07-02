variable "default_ami" {
  description = "AMI ID for EC2 instances (Amazon Linux 2023)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (e.g. t3.small)"
  type        = string
  default     = "t3.small"
}

variable "instance_name" {
  description = "Name tag applied to EC2 instances launched by ASG"
  type        = string
  default     = "drupal-web"
}

variable "web_sg_id" {
  description = "Security group ID attached to web EC2 instances"
  type        = string
}

variable "user_data" {
  description = "Bash script executed at instance launch to install Drupal"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for ASG across multiple AZs"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB target group ARN - ASG registers instances here automatically"
  type        = string
}