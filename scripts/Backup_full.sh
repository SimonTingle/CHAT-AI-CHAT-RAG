#!/bin/bash

# Full Backup Script for Chat AI Project
# Can be run from any directory

echo "📦 FULL BACKUP SCRIPT"
echo "====================="

# Function to find project root
find_project_root() {
    local current_dir="$PWD"
    
    # Look for key project files to identify root
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/package.json" ] && [ -d "$current_dir/client" ] && [ -d "$current_dir/backend" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done
    
    # If not found, try common patterns
    if [ -f "./package.json" ] && [ -d "./client" ] && [ -d "./backend" ]; then
        echo "$PWD"
        return 0
    fi
    
    echo "ERROR: Could not find project root. Make sure you're in the project directory or subdirectory."
    return 1
}

# Get project root
PROJECT_ROOT=$(find_project_root)
if [ $? -ne 0 ]; then
    exit 1
fi

echo "📁 Project root found: $PROJECT_ROOT"

# Create backup directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backup_full_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "📂 Creating backup in: $BACKUP_DIR"

# Function to backup directory
backup_dir() {
    local src_dir="$1"
    local dest_dir="$2"
    local dir_name="$3"
    
    if [ -d "$src_dir" ]; then
        echo "  → Backing up $dir_name..."
        mkdir -p "$dest_dir"
        cp -r "$src_dir"/* "$dest_dir/" 2>/dev/null || echo "    ⚠️  No files to backup in $dir_name"
        echo "    ✅ $dir_name backed up"
    else
        echo "    ⚠️  $dir_name directory not found"
    fi
}

# Function to backup specific files
backup_files() {
    local src_dir="$1"
    local dest_dir="$2"
    local files=("${@:3}")
    
    if [ -d "$src_dir" ]; then
        echo "  → Backing up specific files from $src_dir..."
        mkdir -p "$dest_dir"
        for file in "${files[@]}"; do
            if [ -f "$src_dir/$file" ]; then
                cp "$src_dir/$file" "$dest_dir/" 2>/dev/null
                echo "    ✅ $file"
            else
                echo "    ⚠️  $file (not found)"
            fi
        done
    fi
}

# Backup Client
echo "🖥️  BACKING UP CLIENT..."
CLIENT_DIR="$PROJECT_ROOT/client"
CLIENT_BACKUP="$BACKUP_DIR/client"
mkdir -p "$CLIENT_BACKUP"

# Backup client src directory
backup_dir "$CLIENT_DIR/src" "$CLIENT_BACKUP/src" "Client src"

# Backup client config files
backup_files "$CLIENT_DIR" "$CLIENT_BACKUP" \
    "package.json" \
    "package-lock.json" \
    "vite.config.js" \
    "tailwind.config.js" \
    "index.html" \
    "tsconfig.json" \
    "tsconfig.node.json"

# Backup Backend
echo "⚙️  BACKING UP BACKEND..."
BACKEND_DIR="$PROJECT_ROOT/backend"
BACKEND_BACKUP="$BACKUP_DIR/backend"
mkdir -p "$BACKEND_BACKUP"

# Backup backend src files
backup_dir "$BACKEND_DIR" "$BACKEND_BACKUP" "Backend root files"

# Backup specific backend directories
if [ -d "$BACKEND_DIR/src" ]; then
    backup_dir "$BACKEND_DIR/src" "$BACKEND_BACKUP/src" "Backend src"
fi

if [ -d "$BACKEND_DIR/database" ]; then
    backup_dir "$BACKEND_DIR/database" "$BACKEND_BACKUP/database" "Database"
fi

if [ -d "$BACKEND_DIR/vectorstore" ]; then
    backup_dir "$BACKEND_DIR/vectorstore" "$BACKEND_BACKUP/vectorstore" "Vector Store"
fi

if [ -d "$BACKEND_DIR/logs" ]; then
    backup_dir "$BACKEND_DIR/logs" "$BACKEND_BACKUP/logs" "Logs"
fi

# Backup Root files
echo "📋 BACKING UP ROOT FILES..."
ROOT_BACKUP="$BACKUP_DIR/root"
mkdir -p "$ROOT_BACKUP"

backup_files "$PROJECT_ROOT" "$ROOT_BACKUP" \
    "package.json" \
    "package-lock.json" \
    "docker-compose.yml" \
    "Dockerfile" \
    "README.md" \
    ".env" \
    ".env.example" \
    "tsconfig.json"

# Backup Scripts directory if it exists
if [ -d "$PROJECT_ROOT/scripts" ]; then
    backup_dir "$PROJECT_ROOT/scripts" "$BACKUP_DIR/scripts" "Scripts"
fi

# Create backup info file
cat > "$BACKUP_DIR/backup_info.txt" << EOF
FULL BACKUP INFORMATION
======================

Backup created: $(date)
Project root: $PROJECT_ROOT
Timestamp: $TIMESTAMP

Contents:
- Client src directory
- Client configuration files
- Backend source files
- Backend database files
- Backend vector store
- Backend logs
- Root configuration files
- Scripts directory

Total size: $(du -sh "$BACKUP_DIR" | cut -f1)

To restore:
1. Copy files from backup to respective directories
2. Run npm install in client and backend directories
3. Restore database if needed
4. Check environment variables
EOF

# Create restore script
cat > "$BACKUP_DIR/restore_backup.sh" << 'RESTORE_EOF'
#!/bin/bash

echo "🔄 RESTORE BACKUP SCRIPT"
echo "========================"

if [ ! -f "backup_info.txt" ]; then
    echo "ERROR: This doesn't appear to be a backup directory"
    exit 1
fi

echo "This will restore the backup. Are you sure? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Restore cancelled"
    exit 0
fi

# Restore logic would go here
echo "TODO: Implement restore logic"
echo "Backup contents:"
ls -la

RESTORE_EOF

chmod +x "$BACKUP_DIR/restore_backup.sh"

# Compress backup (optional - uncomment if you want compression)
# echo "🗜️  Compressing backup..."
# tar -czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
# rm -rf "$BACKUP_DIR"
# echo "✅ Backup compressed to ${BACKUP_DIR}.tar.gz"

echo ""
echo "🎉 BACKUP COMPLETED SUCCESSFULLY!"
echo "📂 Backup location: $BACKUP_DIR"
echo "📄 Backup info: $BACKUP_DIR/backup_info.txt"
echo "🔧 Restore script: $BACKUP_DIR/restore_backup.sh"
echo ""
echo "📊 Backup size: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo "📋 Contents:"
find "$BACKUP_DIR" -type d | head -10 | sed 's/^/  📁 /'
find "$BACKUP_DIR" -type f | head -10 | sed 's/^/  📄 /'
echo "  ... and $(($(find "$BACKUP_DIR" -type f | wc -l) - 10)) more files"

