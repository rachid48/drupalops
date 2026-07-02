output "efs_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.drupal.id
}

output "efs_dns_name" {
  description = "EFS DNS name used to mount the file system"
  value       = aws_efs_file_system.drupal.dns_name
}
