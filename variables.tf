variable "instance_type" {
  description = "The type of instance to use"
  type        = string
  default     = "t3.small"
}

variable "default_ami" {
  description = "The default AMI to use for the instance"
  type        = string
  default     = "ami-00034b0b6e2e5a27e"
}

variable "db_instance_class" {
  description = "The type of instance to use"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  }

variable "db_username" {
  description = "The username for the database"
  type        = string
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive = true
  }

variable "default_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-west-3"
}
variable "project_name" {
  type    = string
  default = "drupalops"
}