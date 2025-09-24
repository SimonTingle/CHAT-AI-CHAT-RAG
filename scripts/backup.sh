#!/bin/bash
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up project to $BACKUP_DIR..."

# Backup important files
cp -r backend/db/*.db "$BACKUP_DIR/" 2>/dev/null || true
cp -r backend/vectorstore "$BACKUP_DIR/" 2>/dev/null || true
cp backend/logs/chat.log "$BACKUP_DIR/" 2>/dev/null || true
cp .env "$BACKUP_DIR/" 2>/dev/null || true

echo "Backup completed: $BACKUP_DIR"
