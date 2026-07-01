# Security Group for ALB - allows inbound HTTP from anywhere
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic to ALB"
  vpc_id      = var.vpc_id

ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow HTTP from internet"
}

egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all outbound traffic"
}

  tags = {
    Name = "alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "drupal-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "drupal-alb"
  }
}

# Target Group - points to EC2 instances on port 80
resource "aws_lb_target_group" "drupal" {
  name     = "drupal-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/core/install.php"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "drupal-tg"
  }
}

# Listener - forwards HTTP traffic to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.drupal.arn
  }
}

# Attach EC2 instance to target group
resource "aws_lb_target_group_attachment" "drupal" {
  target_group_arn = aws_lb_target_group.drupal.arn
  target_id        = var.instance_id
  port             = 80
}