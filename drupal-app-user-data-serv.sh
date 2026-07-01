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
