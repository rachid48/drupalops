# Module: cloudwatch

This module provisions CloudWatch monitoring for the Drupal ASG and ALB, including alarms, logs, and a dashboard.

## Why this module

CloudWatch provides operational visibility into instance CPU, ALB error rates, and application logs. It helps detect performance issues and reduces incident response time with email alerts and a centralized dashboard.

## Resources created

- `aws_sns_topic.alarms` — SNS topic used for alarm notifications.
- `aws_sns_topic_subscription.email` — optional email subscription when an alarm email is provided.
- `aws_cloudwatch_metric_alarm.high_cpu` — alarm on average CPU utilization for the ASG.
- `aws_cloudwatch_metric_alarm.high_5xx` — alarm on 5xx errors reported by the ALB.
- `aws_cloudwatch_log_group.drupal_app` — log group for Apache/PHP application logs.
- `aws_cloudwatch_dashboard.main` — dashboard summarizing ASG CPU, active instances, ALB request count, and ALB 5xx errors.

## Inputs

Name | Type | Description
--- | --- | ---
asg_name | string | Name of the Auto Scaling Group to monitor
alb_arn_suffix | string | ARN suffix of the ALB for metric dimensions
target_group_arn_suffix | string | ARN suffix of the Target Group for metric dimensions
alarm_email | string | Email address to notify when alarms trigger. Leave empty to skip email notifications.

## Outputs

Name | Description
--- | ---
dashboard_url | Direct Console URL for the CloudWatch dashboard
log_group_name | Name of the CloudWatch log group for Apache/PHP logs
sns_topic_arn | ARN of the SNS topic used for alarms

## Example usage

```hcl
module "cloudwatch" {
  source                  = "./modules/cloudwatch"
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  alarm_email             = ""
}
```

## Dependencies

This module depends on `module.compute` for the ASG name and `module.alb` for the ALB and target group ARN suffix values.
