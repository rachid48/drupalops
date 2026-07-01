output "public_ip" {
  description = "Public IP address of the web instance"
  value       = "http://${module.compute.public_ip}"
}

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = module.rds.rds_endpoint
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.rds_security_group_id
}
