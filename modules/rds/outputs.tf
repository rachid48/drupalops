output "rds_endpoint" {
  description = "RDS hostname (without port) - use this for the 'Host' field in Drupal install"
  value       = aws_db_instance.default.address
}

output "rds_port" {
  description = "RDS port - use this for the 'Port' field in Drupal install"
  value       = aws_db_instance.default.port
}

output "rds_security_group_id" {
  description = "RDS security group id"
  value       = aws_security_group.rds.id
}
