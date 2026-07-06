# Launch Template - defines instance configuration for ASG
resource "aws_launch_template" "web" {
  name        = "drupal-launch-template"
  description = "Launch template for Drupal web instances managed by ASG"
  image_id      = var.default_ami
  instance_type = var.instance_type
    iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.web_sg_id]
    description                 = "Primary network interface for Drupal instances"
  }

  user_data = base64encode(var.user_data)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = var.instance_name
      Project     = "DrupalOps"
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name      = "drupal-launch-template"
    Project   = "DrupalOps"
    ManagedBy = "Terraform"
  }
}

# Auto Scaling Group - automatically manages EC2 instance count
resource "aws_autoscaling_group" "web" {
  name                = "drupal-asg"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  target_group_arns   = [var.target_group_arn]
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "drupal-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "DrupalOps"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }
}