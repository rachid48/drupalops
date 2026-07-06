# Module: alb

This module provisions an Application Load Balancer and the supporting security group, target group, and listener for Drupal web traffic.

## Why this module

The ALB provides a stable HTTP entry point into the VPC and isolates web traffic from the EC2 fleet. It solves load distribution and health checking across instances, while enabling secure network segmentation through a dedicated ALB security group.

## Resources created

- `aws_security_group.alb` — allows inbound HTTP traffic from the public internet and all outbound traffic for the ALB.
- `aws_lb.main` — creates an internet-facing Application Load Balancer spanning the configured public subnets.
- `aws_lb_target_group.drupal` — defines the HTTP target group for Drupal instances and configures health checks.
- `aws_lb_listener.http` — forwards incoming HTTP requests to the target group.

## Inputs

Name | Type | Description
--- | --- | ---
vpc_id | string | VPC ID
public_subnet_ids | list(string) | List of public subnet IDs for ALB (minimum 2 AZs)

## Outputs

Name | Description
--- | ---
alb_dns_name | DNS name of the ALB
target_group_arn | ARN of the ALB target group
alb_sg_id | Security group ID for the ALB
alb_arn_suffix | ARN suffix of the ALB
target_group_arn_suffix | ARN suffix of the ALB target group

## Example usage

```hcl
module "alb" {
  source            = "./modules/alb"
  vpc_id            = aws_vpc.main.id
  public_subnet_ids = [aws_subnet.main.id, aws_subnet.main_2.id]
}
```

## Dependencies

This module does not depend on other modules under `modules/`, but it is consumed by `module.compute` (via `target_group_arn`), `module.cloudfront` (via `alb_dns_name`), and `module.cloudwatch` (via `alb_arn_suffix` and `target_group_arn_suffix`).
