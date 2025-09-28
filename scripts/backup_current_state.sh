#!/bin/bash

echo "📦 Creating backup of current state..."

# Create backup directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backup_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Backup backend files
cp backend/rag.js "$BACKUP_DIR/rag.js.backup" 2>/dev/null || echo "⚠️  rag.js not found"
cp backend/server.js "$BACKUP_DIR/server.js.backup" 2>/dev/null || echo "⚠️  server.js not found"

# Backup frontend files
cp client/src/components/ModernChat.jsx "$BACKUP_DIR/ModernChat.jsx.backup" 2>/dev/null || echo "⚠️  ModernChat.jsx not found"
cp client/src/hooks/useChat.js "$BACKUP_DIR/useChat.js.backup" 2>/dev/null || echo "⚠️  useChat.js not found"
cp client/src/services/chatService.js "$BACKUP_DIR/chatService.js.backup" 2>/dev/null || echo "⚠️  chatService.js not found"

echo "✅ Backup created in $BACKUP_DIR"
echo "📁 Backup contents:"
ls -la "$BACKUP_DIR"
