#!/bin/bash

set -e

echo "⏰ Setting up cron jobs and system scripts..."

# Create system scripts directory
sudo mkdir -p /usr/local/bin

# Copy system scripts from nested structure
echo "📁 Installing system scripts..."

# Copy backup script
sudo cp system_scripts/mysql_backup_script/mysql_backup.sh /usr/local/bin/

# Copy subscription updater (main script only)
sudo cp system_scripts/subscription_updater/subscription_updater.py /usr/local/bin/

# Copy user management script (main script only)  
sudo cp system_scripts/user_management_software/user_management.py /usr/local/bin/

# Copy software client to web root
sudo cp system_scripts/software_client.py /var/www/html/
sudo chmod 644 /var/www/html/software_client.py

# Make scripts executable
sudo chmod +x /usr/local/bin/mysql_backup.sh
sudo chmod +x /usr/local/bin/subscription_updater.py
sudo chmod +x /usr/local/bin/user_management.py

# Create virtual environments for Python scripts
echo "🐍 Setting up virtual environments for Python scripts..."

# Subscription updater venv
echo "Setting up subscription updater virtual environment..."
sudo mkdir -p /usr/local/lib/subscription_updater
cd /usr/local/lib/subscription_updater
sudo python3 -m venv venv
sudo ./venv/bin/pip install mysql-connector-python

# User management venv  
echo "Setting up user management virtual environment..."
sudo mkdir -p /usr/local/lib/user_management
cd /usr/local/lib/user_management
sudo python3 -m venv venv
sudo ./venv/bin/pip install mysql-connector-python

# Create log directories
sudo mkdir -p /var/log/mysql_backups
sudo mkdir -p /var/log/subscription_updates
sudo chown $USER:$USER /var/log/mysql_backups
sudo chown $USER:$USER /var/log/subscription_updates

# Add cron jobs - using a temporary file to avoid crontab issues
echo "📅 Setting up cron jobs..."

# Create a temporary crontab file
TEMP_CRON=$(mktemp)

# Get existing crontab and remove any of our jobs
if crontab -l 2>/dev/null; then
    crontab -l | grep -v -E "(mysql_backup|subscription_updater|backup cleanup)" > "$TEMP_CRON" || true
else
    > "$TEMP_CRON"
fi

# Add our cron jobs
echo "# Authentication System Cron Jobs" >> "$TEMP_CRON"
echo "0 2 * * * /usr/local/bin/mysql_backup.sh >> /var/log/mysql_backups/backup.log 2>&1" >> "$TEMP_CRON"
echo "0 3 * * * /usr/local/lib/subscription_updater/venv/bin/python3 /usr/local/bin/subscription_updater.py >> /var/log/subscription_updates/updater.log 2>&1" >> "$TEMP_CRON"
echo "0 4 * * * find /var/backups/mysql -name \"*.sql.gz\" -mtime +7 -delete >> /var/log/mysql_backups/cleanup.log 2>&1" >> "$TEMP_CRON"

# Install the new crontab
crontab "$TEMP_CRON"
rm -f "$TEMP_CRON"

echo "✅ Cron jobs installed:"
echo "   - Database backup: Daily at 2 AM"
echo "   - Subscription updates: Daily at 3 AM (using virtual environment)" 
echo "   - Backup cleanup: Daily at 4 AM"

# Display current crontab
echo ""
echo "📋 Current cron jobs:"
crontab -l

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
echo "📊 Log directories created in /var/log/"
echo "💾 Software client available at: /var/www/html/software_client.py"
echo ""
echo "💡 Manual commands:"
echo "   Run subscription update: update_subscriptions"
echo "   Manage users: manage_users"
echo "   Run backup: /usr/local/bin/mysql_backup.sh"
