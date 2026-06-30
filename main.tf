
terraform {

}

// Instance resource definition
resource "aws_instance" "web" {
  ami                    = var.default_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.web.id]
  tags = {
    Name = "WebServer"
  }

user_data = <<-EOF
  #!/bin/bash
  set -e
  export HOME=/root
  export COMPOSER_ALLOW_SUPERUSER=1

  # Mise à jour et installation des paquets
  dnf update -y
  dnf install -y httpd php php-cli php-fpm php-mysqlnd php-xml php-mbstring \
    php-curl php-gd php-zip php-bcmath unzip git

  # Composer
  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer

  # Création du projet Drupal
  mkdir -p /var/www
  cd /var/www
  composer create-project drupal/recommended-project drupal --no-interaction

  # === PERMISSIONS + SELINUX FIX ===
  mkdir -p /var/www/drupal/web/sites/default/files
  chown -R apache:apache /var/www/drupal/web/sites/default
  chmod -R 775 /var/www/drupal/web/sites/default/files

  # SELinux : autoriser Apache à écrire dans files
  if command -v semanage &> /dev/null; then
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/drupal/web/sites/default/files(/.*)?" 2>/dev/null || true
    restorecon -Rv /var/www/drupal/web/sites/default/files
  fi

  # === MOD_REWRITE + CLEAN URLS ===
  sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/' /etc/httpd/conf.modules.d/00-base.conf
  sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/var/www/drupal/web"|' /etc/httpd/conf/httpd.conf
  sed -i 's|<Directory "/var/www/html">|<Directory "/var/www/drupal/web">|' /etc/httpd/conf/httpd.conf
  sed -i 's|AllowOverride None|AllowOverride All|g' /etc/httpd/conf/httpd.conf

  # Démarrage Apache
  systemctl enable httpd
  systemctl restart httpd
EOF

}

output "public_ip" {
  value = aws_instance.web.public_ip
}



resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ou ton IP/32 pour plus de sécurité
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}
// database resource definition

// storage resource definition

// Security




variable "instance_type" {
  description = "The type of instance to use"
  default     = "t3.small"
}

variable "default_ami" {
  description = "The default AMI to use for the instance"
  default     = "ami-00034b0b6e2e5a27e"
}
