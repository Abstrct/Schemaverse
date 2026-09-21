#!/bin/sh
# Nightly logical dump of the game database, keeping BACKUP_KEEP_DAYS days.
# A dump restores with: psql -U postgres -f <file> (roles included via pg_dumpall --roles-only).
set -eu
mkdir -p /backups
while true; do
  stamp=$(date +%Y%m%d-%H%M)
  pg_dumpall --roles-only > "/backups/roles-$stamp.sql"
  pg_dump -Fc -d schemaverse > "/backups/schemaverse-$stamp.dump"
  echo "backup $stamp written"
  find /backups -type f -mtime +"${BACKUP_KEEP_DAYS:-14}" -delete
  sleep 86400
done
