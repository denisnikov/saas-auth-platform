#!/bin/bash

set -e

echo "🗄️ Setting up MySQL database..."

# Load environment variables from the API .venv file
if [ -f "config/.venv" ]; then
    source config/.venv
    echo "✅ Loaded database configuration from .venv"
else
    echo "❌ .venv file not found in config directory"
    exit 1
fi

# Extract database credentials from .venv
DB_HOST=${DB_HOST:-localhost}
DB_NAME=${DB_NAME:-auth_server}
DB_USER=${DB_USER:-auth_admin}
DB_PASS=${DB_PASS}

if [ -z "$DB_PASS" ]; then
    echo "❌ DB_PASS not found in .venv file"
    exit 1
fi

echo "📋 Database configuration:"
echo "   Host: $DB_HOST"
echo "   Database: $DB_NAME"
echo "   User: $DB_USER"

# Function to secure MySQL installation
secure_mysql() {
    echo "🔒 Securing MySQL installation..."
    
    # Check if we're using MySQL or MariaDB
    if mysql --version | grep -q "MariaDB"; then
        echo "📦 Detected MariaDB"
        # MariaDB syntax
        sudo mysql -e "
            SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_PASS}');
            DELETE FROM mysql.user WHERE User='';
            DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
            DROP DATABASE IF EXISTS test;
            DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
            FLUSH PRIVILEGES;
        "
    else
        echo "📦 Detected MySQL"
        # MySQL 8.0+ syntax
        sudo mysql -e "
            ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_PASS}';
            DELETE FROM mysql.user WHERE User='';
            DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
            DROP DATABASE IF EXISTS test;
            DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
            FLUSH PRIVILEGES;
        "
    fi
    
    echo "✅ MySQL secured"
}

# Function to create database and user
setup_database() {
    echo "🗃️ Creating database and user..."
    
    # Create database
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    # Create user and grant privileges
    sudo mysql -e "
        CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
        GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
        GRANT PROCESS ON *.* TO '$DB_USER'@'localhost';
        FLUSH PRIVILEGES;
    "
    
    echo "✅ Database '$DB_NAME' and user '$DB_USER' created"
}

# Function to create tables
create_tables() {
    echo "📊 Creating database tables..."
    
    sudo mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" << 'EOF'
-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    status ENUM('active', 'inactive') DEFAULT 'inactive',
    expiry DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Index for better performance
CREATE INDEX IF NOT EXISTS idx_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_expiry ON users(expiry);
EOF

    echo "✅ Database tables created"
}

# Function to restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        echo "❌ Backup file not found: $backup_file"
        return 1
    fi
    
    echo "🔄 Restoring database from backup: $backup_file"
    
    # Check if backup is compressed
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" | sudo mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"
    else
        sudo mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ Database restored successfully from backup"
        return 0
    else
        echo "❌ Failed to restore database from backup"
        return 1
    fi
}

# Function to prompt for backup restoration
prompt_for_backup() {
    echo ""
    echo "💾 Database Backup Restoration"
    echo "=============================="
    echo "Do you want to restore the database from an existing backup?"
    read -p "Restore from backup? (y/N): " restore_choice
    
    if [[ "$restore_choice" =~ ^[Yy]$ ]]; then
        read -p "Enter the full path to the backup file: " backup_path
        
        if [ -n "$backup_path" ]; then
            if restore_backup "$backup_path"; then
                echo "🎉 Database restoration completed"
                return 0
            else
                echo "❌ Backup restoration failed. Creating fresh database instead."
                return 1
            fi
        else
            echo "❌ No backup path provided. Creating fresh database."
            return 1
        fi
    else
        echo "ℹ️  Creating fresh database without restoration."
        return 1
    fi
}

# Function to create sample data (only for fresh database)
create_sample_data() {
    echo "👥 Creating sample users..."
    
    sudo mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" << 'EOF'
-- Insert sample users with different subscription statuses
INSERT IGNORE INTO users (username, password, status, expiry) VALUES
('admin', MD5('admin123'), 'active', NULL), -- Lifetime subscription
('john_doe', MD5('password123'), 'active', DATE_ADD(CURDATE(), INTERVAL 30 DAY)), -- Active, expires in 30 days
('jane_smith', MD5('password123'), 'inactive', DATE_SUB(CURDATE(), INTERVAL 10 DAY)), -- Inactive, expired 10 days ago
('demo_user', MD5('demo123'), 'active', DATE_ADD(CURDATE(), INTERVAL 7 DAY)); -- Active, expires in 7 days

-- Display created users
SELECT username, status, expiry FROM users;
EOF

    echo "✅ Sample users created"
}

# Main execution
echo "Starting MySQL database setup..."

# Secure MySQL installation
secure_mysql

# Create database and user
setup_database

# Prompt for backup restoration
if ! prompt_for_backup; then
    # If no backup restored, create fresh tables and sample data
    create_tables
    create_sample_data
fi

# Test database connection
echo "🧪 Testing database connection..."
if mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -e "USE $DB_NAME; SELECT 'Connection successful' AS status;" 2>/dev/null; then
    echo "✅ Database connection test successful"
else
    echo "❌ Database connection test failed"
    exit 1
fi

# Display final database info
echo ""
echo "🎉 MySQL database setup completed!"
echo "📊 Database Information:"
echo "   Name: $DB_NAME"
echo "   User: $DB_USER"
echo "   Host: $DB_HOST"
echo ""
echo "👤 Sample users created:"
sudo mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    SELECT 
        username,
        status,
        CASE 
            WHEN expiry IS NULL THEN 'Never (Lifetime)'
            WHEN expiry < CURDATE() THEN CONCAT('Expired (', DATEDIFF(CURDATE(), expiry), ' days ago)')
            ELSE CONCAT('Expires in ', DATEDIFF(expiry, CURDATE()), ' days')
        END as expiry_status
    FROM users 
    ORDER BY username;
" 2>/dev/null || echo "   (Run manually to view users: mysql -u $DB_USER -p $DB_NAME -e 'SELECT username, status, expiry FROM users;')"
