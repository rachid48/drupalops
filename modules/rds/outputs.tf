output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.default.endpoint
}

output "rds_security_group_id" {
  description = "RDS security group id"
  value       = aws_security_group.rds.id
}
