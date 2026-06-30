resource "aws_db_instance" "default" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name



  tags = {
    Name = "drupal-rds"
  }

  lifecycle {
    prevent_destroy = true
  }

}


resource "aws_security_group" "rds" {
  name        = "drupal-rds-sg"
  description = "Allow MySQL from EC2 only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id] # Référence SG, pas IP !
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "drupal-rds-sg"
  }
}

variable "db_instance_class" {
  description = "The type of instance to use"
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "The name of the database"
  default     = "drupaldb"
}

variable "db_username" {
  description = "The username for the database"
  default     = "admin"
}

variable "db_password" {
  description = "The password for the database"
  default     = "admin1234"
}

output "rds_endpoint" {
  value = aws_db_instance.default.endpoint
}