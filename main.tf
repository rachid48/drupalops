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

module "alb" {
  source            = "./modules/alb"
  vpc_id            = aws_vpc.main.id
  public_subnet_ids = [aws_subnet.main.id, aws_subnet.main_2.id]
  instance_id       = module.compute.instance_id
}

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id

  # Allow HTTP only from ALB security group
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb.alb_sg_id]
    description     = "Allow HTTP from ALB only"
  }

  # Allow SSH for administration
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH for administration"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = { Name = "web-sg" }
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}