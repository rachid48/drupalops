# Module: compute

This module provisions EC2 compute capacity for Drupal using a launch template and Auto Scaling Group.

## Why this module

The module provides scalable, managed web servers behind the ALB. It uses an ASG to maintain availability, allows instance profile-based access for secrets, and supports user data provisioning so instances can self-bootstrap Drupal.

## Resources created

- `aws_launch_template.web` — defines the EC2 launch configuration, network settings, IAM instance profile, and boot-time user data.
- `aws_autoscaling_group.web` — manages the desired number of Drupal web instances, registers them with the ALB target group, and performs health checks.

## Inputs

Name | Type | Description
--- | --- | ---
default_ami | string | AMI ID for EC2 instances (Amazon Linux 2023)
instance_type | string | EC2 instance type (e.g. t3.small)
instance_name | string | Name tag applied to EC2 instances launched by ASG
web_sg_id | string | Security group ID attached to web EC2 instances
user_data | string | Bash script executed at instance launch to install Drupal
subnet_ids | list(string) | List of public subnet IDs for ASG across multiple AZs
target_group_arn | string | ALB target group ARN - ASG registers instances here automatically
iam_instance_profile_name | string | IAM instance profile to attach to EC2 instances

## Outputs

Name | Description
--- | ---
asg_name | Name of the Auto Scaling Group
launch_template_id | ID of the Launch Template used by the ASG

## Example usage

```hcl
module "compute" {
  source                   = "./modules/compute"
  default_ami              = var.default_ami
  instance_type            = var.instance_type
  instance_name            = "drupal-web"
  web_sg_id                = aws_security_group.web.id
  iam_instance_profile_name = module.iam.instance_profile_name
  user_data                = templatefile("${path.module}/scripts/install-drupal.sh", {
    efs_id      = module.efs.efs_id
    aws_region  = "eu-west-3"
    mount_efs   = file("${path.module}/scripts/mount-efs.sh")
    secret_name = "drupalops-db-credentials"
  })
  subnet_ids       = [aws_subnet.main.id, aws_subnet.main_2.id]
  target_group_arn = module.alb.target_group_arn
}
```

## Dependencies

This module depends on `module.alb` for the target group ARN, `module.efs` for shared storage mount configuration, and `module.iam` for the IAM instance profile attached to EC2 instances.
