module "compute" {
  source        = "./modules/compute"
  default_ami   = var.default_ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main.id
  web_sg_id     = aws_security_group.web.id
  user_data     = file("${path.module}/drupal-app-user-data-serv.sh")
}

module "rds" {
  source               = "./modules/rds"
  db_instance_class    = var.db_instance_class
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_id               = aws_vpc.main.id
  web_sg_id            = aws_security_group.web.id
}

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}
