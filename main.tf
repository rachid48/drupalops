module "compute" {
  source           = "./modules/compute"
  default_ami      = var.default_ami
  instance_type    = var.instance_type
  instance_name    = "drupal-web"
  web_sg_id        = aws_security_group.web.id
  iam_instance_profile_name = module.iam.instance_profile_name

  user_data        = templatefile("${path.module}/scripts/install-drupal.sh", {
    efs_id      = module.efs.efs_id
    aws_region  = "eu-west-3"
    mount_efs   = file("${path.module}/scripts/mount-efs.sh")
    secret_name = "drupalops-db-credentials"
  })
  subnet_ids       = [aws_subnet.main.id, aws_subnet.main_2.id]
  target_group_arn = module.alb.target_group_arn
}

module "efs" {
  source     = "./modules/efs"
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.main.id, aws_subnet.main_2.id]
  web_sg_id  = aws_security_group.web.id
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
}

module "cloudfront" {
  source       = "./modules/cloudfront"
  alb_dns_name = module.alb.alb_dns_name
}

module "cloudwatch" {
  source                  = "./modules/cloudwatch"
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  alarm_email             = ""
}

resource "random_id" "hash_salt" {
  byte_length = 32
}

module "secrets" {
  source       = "./modules/secrets"
  project_name = var.project_name
  db_username  = var.db_username
  db_password  = var.db_password
  db_host      = module.rds.rds_endpoint
  db_port      = module.rds.rds_port
  db_name      = var.db_name
  hash_salt    = random_id.hash_salt.hex
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  secret_arn   = module.secrets.secret_arn
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
