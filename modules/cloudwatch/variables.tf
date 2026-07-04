variable "asg_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (required format for CloudWatch metrics)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the Target Group (required format for CloudWatch metrics)"
  type        = string
}

variable "alarm_email" {
  description = "Email address to notify when an alarm triggers. Leave empty to skip email notifications."
  type        = string
  default     = ""
}