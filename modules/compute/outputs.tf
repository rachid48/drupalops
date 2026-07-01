output "instance_id" {
  description = "ID of the web instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP address of the web instance"
  value       = aws_instance.web.public_ip
}