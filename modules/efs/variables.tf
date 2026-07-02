variable "vpc_id" {
  description = "VPC ID where EFS will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EFS mount targets (one per AZ)"
  type        = list(string)
}

variable "web_sg_id" {
  description = "Security group ID of web EC2 instances allowed to mount EFS"
  type        = string
}
