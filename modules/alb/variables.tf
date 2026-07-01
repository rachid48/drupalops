# modules/alb/variables.tf

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB (minimum 2 AZs)"
  type        = list(string)
}

variable "instance_id" {
  description = "EC2 instance ID to attach to target group"
  type        = string
}