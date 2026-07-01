# VPC
resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "main-drupal-vpc" }
}

# Primary public subnet - AZ eu-west-3c
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "eu-west-3c"
  map_public_ip_on_launch = true
  tags = { Name = "front-app-subnet" }
}

# Secondary public subnet for ALB - AZ eu-west-3b
resource "aws_subnet" "main_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.4.0/24"
  availability_zone       = "eu-west-3b"
  map_public_ip_on_launch = true
  tags = { Name = "front-app-subnet-2" }
}

# Private subnet for RDS - AZ eu-west-3c
resource "aws_subnet" "db_private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "eu-west-3c"
  tags = { Name = "db-subnet-private-1" }
}

# Private subnet for RDS - AZ eu-west-3b
resource "aws_subnet" "db_private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = "eu-west-3b"
  tags = { Name = "db-subnet-private-2" }
}

# DB subnet group
resource "aws_db_subnet_group" "default" {
  name       = "drupal-db-subnet-group"
  subnet_ids = [aws_subnet.db_private_1.id, aws_subnet.db_private_2.id]
  tags = { Name = "drupal-db-subnet-group" }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Associate primary subnet with route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

# Associate secondary subnet with route table
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.main_2.id
  route_table_id = aws_route_table.public.id
}