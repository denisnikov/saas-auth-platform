#!/bin/bash

set -e

echo "⏰ Setting up cron jobs and system scripts..."

# Create system scripts directory
sudo mkdir -p /usr/local/bin
sudo chown $USER:$USER /usr/local/bin

# Copy system scripts from nested structure
echo "📁 Installing system scripts..."

# Copy backup script
sudo cp system_scripts/mysql_backup_script/mysql_backup.sh /usr/local/bin/

# Copy subscription updater (main script only)
sudo cp system_scripts/subscription_updater/subscription_updater.py /usr/local/bin/

# Copy user management script (main script only)  
sudo cp system_scripts/user_management_software/user_management.py /usr/local/bin/

# Copy software client to web downloads
sudo mkdir -p /var/www/html/downloads
sudo cp system_scripts/software_client.py /var/www/html/downloads/
sudo chmod 644 /var/www/html/downloads/software_client.py

# Make scripts executable
sudo chmod +x /usr/local/bin/mysql_backup.sh
sudo chmod +x /usr/local/bin/subscription_updater.py
sudo chmod +x /usr/local/bin/user_management.py

# Create virtual environments for Python scripts
echo "🐍 Setting up virtual environments for Python scripts..."

# Subscription updater venv
echo "Setting up subscription updater virtual environment..."
sudo mkdir -p /usr/local/lib/subscription_updater
sudo cp -r system_scripts/subscription_updater/venv /usr/local/lib/subscription_updater/
sudo chmod -R 755 /usr/local/lib/subscription_updater

# User management venv  
echo "Setting up user management virtual environment..."
sudo mkdir -p /usr/local/lib/user_management
sudo cp -r system_scripts/user_management_software/venv /usr/local/lib/user_management/
sudo chmod -R 755 /usr/local/lib/user_management

# Create log directories
sudo mkdir -p /var/log/mysql_backups
sudo mkdir -p /var/log/subscription_updates
sudo chown $USER:$USER /var/log/mysql_backups
sudo chown $USER:$USER /var/log/subscription_updates

# Add cron jobs
echo "📅 Setting up cron jobs..."

# Backup cron job (daily at 2 AM)
(crontab -l 2>/dev/null | grep -v "/usr/local/bin/mysql_backup.sh"; echo "0 2 * * * /usr/local/bin/mysql_backup.sh >> /var/log/mysql_backups/backup.log 2>&1") | crontab -

# Subscription updater cron job (daily at 3 AM) - uses its own venv
(crontab -l 2>/dev/null | grep -v "subscription_updater.py"; echo "0 3 * * * /usr/local/lib/subscription_updater/venv/bin/python3 /usr/local/bin/subscription_updater.py >> /var/log/subscription_updates/updater.log 2>&1") | crontab -

# Cleanup old backup files (daily at 4 AM)
(crontab -l 2>/dev/null | grep -v "find /var/backups/mysql"; echo "0 4 * * * find /var/backups/mysql -name \"*.sql.gz\" -mtime +7 -delete >> /var/log/mysql_backups/cleanup.log 2>&1") | crontab -

echo "✅ Cron jobs installed:"
echo "   - Database backup: Daily at 2 AM"
echo "   - Subscription updates: Daily at 3 AM (using virtual environment)" 
echo "   - Backup cleanup: Daily at 4 AM"

# Display current crontab
echo ""
echo "📋 Current cron jobs:"
crontab -l

# Create initial log files
sudo touch /var/log/mysql_backups/backup.log
sudo touch /var/log/subscription_updates/updater.log
sudo chown $USER:$USER /var/log/mysql_backups/backup.log
sudo chown $USER:$USER /var/log/subscription_updates/updater.log

# Create wrapper scripts for easy manual execution
echo "🔧 Creating wrapper scripts for manual execution..."

# Wrapper for subscription updater
sudo tee /usr/local/bin/update_subscriptions > /dev/null <<'EOF'
#!/bin/bash
/usr/local/lib/subscription_updater/venv/bin/python3 /usr/local/bin/subscription_updater.py
EOF

# Wrapper for user management
sudo tee /usr/local/bin/manage_users > /dev/null <<'EOF'
#!/bin/bash
/usr/local/lib/user_management/venv/bin/python3 /usr/local/bin/user_management.py
EOF

sudo chmod +x /usr/local/bin/update_subscriptions
sudo chmod +x /usr/local/bin/manage_users

echo ""
echo "✅ Cron jobs setup completed!"
echo "📁 System scripts installed in /usr/local/bin/"
echo "🐍 Virtual environments set up in /usr/local/lib/"
echo "📊 Logs will be stored in /var/log/mysql_backups/ and /var/log/subscription_updates/"
echo ""
echo "💡 Manual commands:"
echo "   Run subscription update: update_subscriptions"
echo "   Manage users: manage_users"
echo "   Run backup: /usr/local/bin/mysql_backup.sh"
