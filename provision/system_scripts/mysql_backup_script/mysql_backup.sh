#!/bin/bash

# MySQL Database Backup Script
# Uses /etc/demo/.venv for configuration

# Load environment variables
source /etc/demo/.venv

# Configuration
BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$DATE.sql"
LOG_FILE="/var/log/mysql_backups/backup.log"

# Ensure backup directory exists and has proper permissions
sudo mkdir -p "$BACKUP_DIR"
sudo chown $USER:$USER "$BACKUP_DIR"
sudo chmod 755 "$BACKUP_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE"
}

# Start backup
log "Starting MySQL backup of database: $DB_NAME"

# Perform the backup
if mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | sudo tee "$BACKUP_FILE" > /dev/null; then
    # Compress the backup
    if sudo gzip "$BACKUP_FILE"; then
        BACKUP_FILE="${BACKUP_FILE}.gz"
        FILE_SIZE=$(sudo du -h "$BACKUP_FILE" | cut -f1)
        log "Backup completed successfully: $BACKUP_FILE ($FILE_SIZE)"
    else
        log "Failed to compress backup: $BACKUP_FILE"
        exit 1
    fi
else
    log "MySQL dump failed for database: $DB_NAME"
    exit 1
fi

# Set proper ownership of the backup file
sudo chown $USER:$USER "${BACKUP_FILE}.gz"

log "Backup process completed"
