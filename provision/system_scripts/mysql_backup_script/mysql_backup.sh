#!/bin/bash

# MySQL Database Backup Script
# Backs up the database daily and maintains backups for 7 days

# Load environment variables
source /etc/demo/.venv

# Configuration
BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$DATE.sql"
LOG_FILE="/var/log/mysql_backup.log"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Start backup
log "🔧 Starting MySQL backup of database: $DB_NAME"

# Perform the backup
if mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE" 2>> "$LOG_FILE"; then
    # Compress the backup
    if gzip "$BACKUP_FILE"; then
        BACKUP_FILE="${BACKUP_FILE}.gz"
        FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        log "✅ Backup completed successfully: $BACKUP_FILE ($FILE_SIZE)"
    else
        log "❌ Failed to compress backup: $BACKUP_FILE"
        exit 1
    fi
else
    log "❌ MySQL dump failed for database: $DB_NAME"
    exit 1
fi

# Clean up old backups (keep last 7 days)
find "$BACKUP_DIR" -name "${DB_NAME}_backup_*.sql.gz" -mtime +7 -delete >> "$LOG_FILE" 2>&1

log "🧹 Cleaned up backups older than 7 days"
log "🎉 Backup process completed"
