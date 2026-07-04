output "dashboard_url" {
  description = "Direct link to the CloudWatch dashboard in the AWS console"
  value       = "https://eu-west-3.console.aws.amazon.com/cloudwatch/home?region=eu-west-3#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "log_group_name" {
  description = "Name of the CloudWatch Log Group receiving Apache/PHP logs"
  value       = aws_cloudwatch_log_group.drupal_app.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for alarm notifications"
  value       = aws_sns_topic.alarms.arn
}