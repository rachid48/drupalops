# SNS topic - where alarm notifications get sent
resource "aws_sns_topic" "alarms" {
  name = "drupalops-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Alarm 1 - High CPU on the Auto Scaling Group
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "drupalops-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when average CPU usage across the ASG exceeds 80% for 10 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# Alarm 2 - High rate of 5xx errors on the ALB
resource "aws_cloudwatch_metric_alarm" "high_5xx" {
  alarm_name          = "drupalops-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Triggers when the ALB reports more than 5 server errors (5xx) in 5 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# Alarm 3 - Apache unavailable on at least one ASG instance
resource "aws_cloudwatch_metric_alarm" "apache_down" {
  alarm_name          = "drupalops-apache-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  alarm_description   = "Triggers when Apache has no running process for 2 minutes"
  treat_missing_data  = "breaching"

  metric_query {
    id          = "apache"
    expression  = "SELECT MIN(procstat_lookup_pid_count) FROM \"DrupalOps\" WHERE AutoScalingGroupName = '${var.asg_name}' AND pattern = 'httpd'"
    period      = 60
    return_data = true
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# Alarm 4 - High memory usage on at least one ASG instance
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "drupalops-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 80
  alarm_description   = "Triggers when memory usage exceeds 80% for 5 minutes"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "memory"
    expression  = "SELECT MAX(mem_used_percent) FROM \"DrupalOps\" WHERE AutoScalingGroupName = '${var.asg_name}'"
    period      = 60
    return_data = true
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# Alarm 5 - Root disk nearly full on at least one ASG instance
resource "aws_cloudwatch_metric_alarm" "high_disk" {
  alarm_name          = "drupalops-high-disk"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 80
  alarm_description   = "Triggers when root disk usage exceeds 80% for 5 minutes"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "disk"
    expression  = "SELECT MAX(disk_used_percent) FROM \"DrupalOps\" WHERE AutoScalingGroupName = '${var.asg_name}' AND path = '/'"
    period      = 60
    return_data = true
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# Log Group - destination for Apache/PHP logs from EC2 instances
resource "aws_cloudwatch_log_group" "drupal_app" {
  name              = "/drupalops/apache-php"
  retention_in_days = 14

  tags = {
    Project = "DrupalOps"
  }
}

# Dashboard - infrastructure and application health overview
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "DrupalOps-Overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CPU Utilization (ASG)"
          view   = "timeSeries"
          region = "eu-west-3"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Active Instances (ASG)"
          view   = "timeSeries"
          region = "eu-west-3"
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Requests Count (ALB)"
          view   = "timeSeries"
          region = "eu-west-3"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "5xx Errors (ALB)"
          view   = "timeSeries"
          region = "eu-west-3"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Memory Used (%)"
          view   = "timeSeries"
          region = "eu-west-3"
          metrics = [
            [{
              expression = "SEARCH('{DrupalOps,AutoScalingGroupName,InstanceId} MetricName=\"mem_used_percent\" AutoScalingGroupName=\"${var.asg_name}\"', 'Average', 60)"
              id         = "memory"
            }]
          ]
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Root Disk Used (%)"
          view   = "timeSeries"
          region = "eu-west-3"
          metrics = [
            [{
              expression = "SEARCH('{DrupalOps,AutoScalingGroupName,InstanceId,device,fstype,path} MetricName=\"disk_used_percent\" AutoScalingGroupName=\"${var.asg_name}\" path=\"/\"', 'Average', 60)"
              id         = "disk"
            }]
          ]
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "Apache Process Count"
          view   = "timeSeries"
          region = "eu-west-3"
          metrics = [
            [{
              expression = "SEARCH('{DrupalOps,AutoScalingGroupName,InstanceId,pattern,pid_finder} MetricName=\"procstat_lookup_pid_count\" AutoScalingGroupName=\"${var.asg_name}\" pattern=\"httpd\"', 'Average', 60)"
              id         = "apache"
            }]
          ]
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "Recent Apache/PHP Logs"
          view   = "table"
          region = "eu-west-3"
          query  = "SOURCE '${aws_cloudwatch_log_group.drupal_app.name}' | fields @timestamp, @logStream, @message | sort @timestamp desc | limit 20"
        }
      }
    ]
  })
}
