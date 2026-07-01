variable "db_instance_class" {
  description = "The type of RDS instance to use"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "drupaldb"
}

variable "db_username" {
  description = "The username for the database"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  default     = "admin1234"
}

variable "db_subnet_group_name" {
  description = "The DB subnet group name"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where RDS will be deployed"
  type        = string
}

variable "web_sg_id" {
  description = "The security group ID of the web server allowed to reach RDS"
  type        = string
}

variable "sg_name" {
  description = "The security group name for RDS"
  type        = string
  default     = "drupal-rds-sg"
}
