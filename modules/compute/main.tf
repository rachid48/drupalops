resource "aws_instance" "web" {
  ami                    = var.default_ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.web_sg_id]

  user_data = var.user_data

  tags = {
    Name = var.instance_name
  }
}
output "instance_id" {
  description = "ID of the web instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP address of the web instance"
  value       = aws_instance.web.public_ip
}