#!/bin/bash

# Define backup parameters
BACKUP_DIR="/home/guy/scripts"
DAYS_TO_KEEP=5
FILE_SUFFIX="_pg_backup.sql"
DATABASE="godot_game"
USER="godot_user"
PGPASSWORD="Aa123456"
LOG_DIR="/var/log/PGBACKUP"

# Create a timestamp for both backup and log file
DATE_TIMESTAMP=$(date +"%Y%m%d%H%M")
LOG_FILE="${LOG_DIR}/backup_${DATE_TIMESTAMP}.log"

# Set working directory to BACKUP_DIR
cd "$BACKUP_DIR" || exit

# Generate a timestamped filename for the backup
FILE="${DATE_TIMESTAMP}${FILE_SUFFIX}"
OUTPUT_FILE="${BACKUP_DIR}/${FILE}"

# Log the start of the backup process
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Starting backup..." >> "$LOG_FILE"

# Perform the database backup (pg_dump)
{
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Running pg_dump for database: ${DATABASE}..."
    PGPASSWORD="$PGPASSWORD" pg_dump -U "$USER" "$DATABASE" -F p -f "$OUTPUT_FILE"

    if [ $? -eq 0 ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Database backup successful."
    else
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Database backup failed." >&2
        exit 1
    fi
} >> "$LOG_FILE" 2>&1

# Compress the database dump using gzip
{
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Compressing the backup..."
    gzip -f "$OUTPUT_FILE"

    if [ $? -eq 0 ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Gzip compression successful."
    else
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Gzip compression failed." >&2
        exit 1
    fi
} >> "$LOG_FILE" 2>&1

# Show the user the result of the backup file
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup file created: ${OUTPUT_FILE}.gz" >> "$LOG_FILE"
ls -l "${OUTPUT_FILE}.gz" >> "$LOG_FILE"

# Prune old backups
{
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Pruning backups older than ${DAYS_TO_KEEP} days..."
    find "$BACKUP_DIR" -maxdepth 1 -mtime +$DAYS_TO_KEEP -name "*${FILE_SUFFIX}.gz" -exec rm -rf '{}' \;

    if [ $? -eq 0 ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Old backups pruned successfully."
    else
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Failed to prune old backups." >&2
    fi
} >> "$LOG_FILE" 2>&1

#  Log retention: Delete logs older than ${DAYS_TO_KEEP} days
{
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Pruning old logs older than ${DAYS_TO_KEEP} days..."
    find "$LOG_DIR" -maxdepth 1 -type f -name "backup_*.log" -mtime +$DAYS_TO_KEEP -exec rm -rf '{}' \;

    if [ $? -eq 0 ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Old logs pruned successfully."
    else
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Failed to prune old logs." >&2
    fi
} >> "$LOG_FILE" 2>&1

# Log the completion of the backup process
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup completed." >> "$LOG_FILE"
