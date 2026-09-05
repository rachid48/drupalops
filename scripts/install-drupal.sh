#!/bin/bash
set -e
export HOME=/root
export COMPOSER_ALLOW_SUPERUSER=1

# Update system and install required packages
dnf update -y
dnf install -y httpd php php-cli php-fpm php-mysqlnd php-xml php-mbstring \
  php-curl php-gd php-zip php-bcmath unzip git aws-cli jq mariadb105 \
  amazon-cloudwatch-agent

# Install the CloudWatch Agent configuration delivered by Terraform user data.
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOCWCONFIG'
${cloudwatch_config}
EOCWCONFIG

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Create Drupal project
mkdir -p /var/www
cd /var/www
composer create-project drupal/recommended-project drupal --no-interaction

# === PERMISSIONS + SELINUX ===
mkdir -p /var/www/drupal/web/sites/default/files
chown -R apache:apache /var/www/drupal/web/sites/default
chmod -R 775 /var/www/drupal/web/sites/default/files

if command -v semanage &> /dev/null; then
  semanage fcontext -a -t httpd_sys_rw_content_t \
    "/var/www/drupal/web/sites/default/files(/.*)?" 2>/dev/null || true
  restorecon -Rv /var/www/drupal/web/sites/default/files
fi

# === MOD_REWRITE + CLEAN URLS ===
sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/' \
  /etc/httpd/conf.modules.d/00-base.conf
sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/var/www/drupal/web"|' \
  /etc/httpd/conf/httpd.conf
sed -i 's|<Directory "/var/www/html">|<Directory "/var/www/drupal/web">|' \
  /etc/httpd/conf/httpd.conf
sed -i 's|AllowOverride None|AllowOverride All|g' \
  /etc/httpd/conf/httpd.conf

# === MOUNT EFS FOR SHARED DRUPAL FILES ===
cat > /tmp/mount-efs.sh << EOFEFS
${mount_efs}
EOFEFS
chmod +x /tmp/mount-efs.sh
export efs_id="${efs_id}"
export mount_path="/var/www/drupal/web/sites/default/files"
export aws_region="${aws_region}"
bash /tmp/mount-efs.sh

chown -R apache:apache /var/www/drupal/web/sites/default/files

# === FETCH DB CREDENTIALS + HASH SALT FROM SECRETS MANAGER ===
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id ${secret_name} \
  --region ${aws_region} \
  --query SecretString \
  --output text)

DB_USERNAME=$(echo "$SECRET_JSON" | jq -r .username)
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)
DB_HOST=$(echo "$SECRET_JSON" | jq -r .host)
DB_PORT=$(echo "$SECRET_JSON" | jq -r .port)
DB_NAME=$(echo "$SECRET_JSON" | jq -r .dbname)
HASH_SALT=$(echo "$SECRET_JSON" | jq -r .hash_salt)

# === INSTALL DRUSH ===
cd /var/www/drupal
composer require drush/drush --no-interaction

# === CHECK IF DATABASE IS ALREADY INITIALIZED ===
# Counts tables in the DB. If > 0, Drupal was already installed by a
# previous instance (or a previous deploy) — do NOT reinstall, just
# generate settings.php so this new instance points to the existing DB.
TABLE_COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" \
  -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB_NAME';")

if [ "$TABLE_COUNT" -eq "0" ]; then
  echo "Empty database detected — running fresh Drupal install..."
  vendor/bin/drush site:install standard \
    --db-url="mysql://$${DB_USERNAME}:$${DB_PASSWORD}@$${DB_HOST}:$${DB_PORT}/$${DB_NAME}" \
    --site-name="DrupalOps" \
    --account-name=admin \
    --account-pass=admin \
    --yes

  # Force the shared hash_salt after install so future instances
  # can validate the same session/CSRF tokens.
  echo "" >> /var/www/drupal/web/sites/default/settings.php
  echo "\$settings['hash_salt'] = '$HASH_SALT';" >> /var/www/drupal/web/sites/default/settings.php

else
  echo "Existing database detected ($TABLE_COUNT tables) — generating settings.php only, skipping install."

  SETTINGS_DIR="/var/www/drupal/web/sites/default"
  cp "$SETTINGS_DIR/default.settings.php" "$SETTINGS_DIR/settings.php"

  cat >> "$SETTINGS_DIR/settings.php" << EOSETTINGS

\$databases['default']['default'] = [
  'database' => '$DB_NAME',
  'username' => '$DB_USERNAME',
  'password' => '$DB_PASSWORD',
  'host' => '$DB_HOST',
  'port' => '$DB_PORT',
  'driver' => 'mysql',
  'prefix' => '',
];
\$settings['hash_salt'] = '$HASH_SALT';
EOSETTINGS

  chown apache:apache "$SETTINGS_DIR/settings.php"
  chmod 644 "$SETTINGS_DIR/settings.php"
fi

# === START APACHE ===
systemctl enable httpd
systemctl restart httpd

# Start infrastructure metrics and Apache/cloud-init log collection.
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
systemctl enable amazon-cloudwatch-agent
