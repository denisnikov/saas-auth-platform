#!/bin/bash

set -e

echo "🌐 Setting up web server and PHP application..."

# Install Apache and PHP if not already installed
if ! command -v apache2 &> /dev/null; then
    echo "📦 Installing Apache..."
    sudo apt install -y apache2
fi

if ! command -v php &> /dev/null; then
    echo "📦 Installing PHP..."
    sudo apt install -y php php-mysql libapache2-mod-php
fi

# Enable Apache modules
sudo a2enmod rewrite
sudo a2enmod php8.4  # Adjust version if needed

# Create web directory structure
sudo mkdir -p /var/www/html
sudo chown $USER:$USER /var/www/html

# Copy PHP files to web directory with sudo
echo "📁 Copying PHP files to /var/www/html..."
sudo cp www/register.php /var/www/html/
sudo cp www/login.php /var/www/html/
sudo cp www/env_loader.php /var/www/html/

# Copy .htaccess if it exists
if [ -f "www/.htaccess" ]; then
    sudo cp www/.htaccess /var/www/html/
    echo "✅ .htaccess copied"
fi

# Copy software client to web directory for download
sudo chmod 644 /var/www/html/downloads/software_client.py

# Set proper permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod 755 /var/www/html
sudo chmod 644 /var/www/html/*.php
sudo chmod 644 /var/www/html/env_loader.php

# Create Apache virtual host configuration
echo "📝 Configuring Apache virtual host..."
sudo tee /etc/apache2/sites-available/authentication.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/authentication_error.log
    CustomLog \${APACHE_LOG_DIR}/authentication_access.log combined
</VirtualHost>
EOF

# Enable the site and disable default
sudo a2ensite authentication.conf
sudo a2dissite 000-default.conf

# Restart Apache to apply changes
echo "🔄 Restarting Apache..."
sudo systemctl restart apache2

# Enable Apache to start on boot
sudo systemctl enable apache2

# Test PHP configuration
echo "🧪 Testing PHP configuration..."
php -v

# Create a simple info.php for testing (remove in production)
sudo tee /var/www/html/info.php > /dev/null <<'EOF'
<?php
// Remove this file in production - for testing only
phpinfo();
?>
EOF

sudo chown www-data:www-data /var/www/html/info.php

echo "✅ Web server setup completed!"
echo "📊 Apache status: $(sudo systemctl is-active apache2)"
echo "🌐 Web interface will be available at: http://$(hostname -I | awk '{print $1}')/login.php"
