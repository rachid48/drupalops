#!/bin/bash
set -e
export HOME=/root
export COMPOSER_ALLOW_SUPERUSER=1

# Update system and install required packages
dnf update -y
dnf install -y httpd php php-cli php-fpm php-mysqlnd php-xml php-mbstring \
  php-curl php-gd php-zip php-bcmath unzip git

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Create Drupal project
mkdir -p /var/www
cd /var/www
composer create-project drupal/recommended-project drupal --no-interaction

# === PERMISSIONS + SELINUX FIX ===
mkdir -p /var/www/drupal/web/sites/default/files
chown -R apache:apache /var/www/drupal/web/sites/default
chmod -R 775 /var/www/drupal/web/sites/default/files

# Allow Apache to write to files directory (SELinux)
if command -v semanage &> /dev/null; then
  semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/drupal/web/sites/default/files(/.*)?" 2>/dev/null || true
  restorecon -Rv /var/www/drupal/web/sites/default/files
fi

# === MOD_REWRITE + CLEAN URLS ===
sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/' /etc/httpd/conf.modules.d/00-base.conf
sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/var/www/drupal/web"|' /etc/httpd/conf/httpd.conf
sed -i 's|<Directory "/var/www/html">|<Directory "/var/www/drupal/web">|' /etc/httpd/conf/httpd.conf
sed -i 's|AllowOverride None|AllowOverride All|g' /etc/httpd/conf/httpd.conf

# === EFS SHARED STORAGE ===
# Wait for EFS mount target to be available across AZs
sleep 20

# Mount EFS via NFS4 (more reliable than efs-utils on AL2023)
mount -t nfs4 \
  -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
  ${efs_id}.efs.eu-west-3.amazonaws.com:/ \
  /var/www/drupal/web/sites/default/files || true

# Persist EFS mount across reboots
echo "${efs_id}.efs.eu-west-3.amazonaws.com:/ /var/www/drupal/web/sites/default/files nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab

# Fix permissions on shared EFS storage
chown -R apache:apache /var/www/drupal/web/sites/default/files

# === START APACHE ===
systemctl enable httpd
systemctl restart httpd