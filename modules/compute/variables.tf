variable "default_ami" {
  description = "The default AMI to use for the instance"
  type        = string
  default     = "ami-00034b0b6e2e5a27e"
}

variable "instance_type" {
  description = "The type of instance to use"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "The subnet id where the instance will be launched"
  type        = string
}

variable "web_sg_id" {
  description = "The security group id for the web instance"
  type        = string
}

variable "user_data" {
  description = "User data script for the instance"
  type        = string
}

variable "instance_name" {
  description = "The name tag for the instance"
  type        = string
  default     = "WebServer"
}
