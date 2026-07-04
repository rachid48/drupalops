output "alb_dns_name" {
  description = "ALB DNS name - use this to access Drupal"
  value       = "http://${module.alb.alb_dns_name}"
}

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = module.rds.rds_endpoint
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.rds_security_group_id
}
output "site_url" {
  description = "URL publique du site Drupal (via CloudFront)"
  value       = "https://${module.cloudfront.cloudfront_domain_name}"
}