#!/bin/bash

# Completion script for chatbotai deployment

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if we are in the target directory (the one that was being created)
if [ ! -f "package.json" ] || [ ! -d "backend" ] || [ ! -d "client" ]; then
    log_error "This script must be run in the target project directory."
    exit 1
fi

# Phase 6: Documentation and scripts (continued)
log_info "Creating README..."
cat > README.md << 'EOF'
# AI Chatbot with RAG and Memory

... (the content of the README as in the original script)
EOF

log_info "Creating utility scripts..."
mkdir -p scripts

cat > scripts/setup.sh << 'EOF'
#!/bin/bash
echo "Setting up AI Chatbot project..."

# Check for Ollama
if ! command -v ollama &> /dev/null; then
    echo "Warning: Ollama not found. Please install from https://ollama.ai/"
fi

# Create data directories
mkdir -p backend/db backend/vectorstore backend/logs data

echo "Setup complete!"
EOF

chmod +x scripts/setup.sh

cat > scripts/backup.sh << 'EOF'
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
EOF

chmod +x scripts/backup.sh

log_info "Phase 6 completed."

# Phase 7: Dependency installation
log_info "Installing root dependencies..."
npm install

log_info "Installing client dependencies..."
cd client
npm install
cd ..

log_info "Phase 7 completed."

# Phase 8: Final setup and validation
log_info "Running project setup script..."
chmod +x scripts/setup.sh
./scripts/setup.sh

log_info "Creating initial environment file..."
cp .env.example .env

log_info "Initializing database..."
node -e "
const { initDB } = require('./backend/db.js');
initDB();
console.log('Database initialized successfully');
"

log_info "Validating project structure..."

# Check critical files and directories
check_file() {
    if [ ! -f "$1" ]; then
        log_error "Missing file: $1"
        return 1
    fi
}

check_dir() {
    if [ ! -d "$1" ]; then
        log_error "Missing directory: $1"
        return 1
    fi
}

# Critical files
check_file "package.json"
check_file "backend/server.js"
check_file "backend/package.json"
check_file "client/package.json"
check_file "client/src/App.jsx"
check_file "README.md"
check_file ".env.example"

# Critical directories
check_dir "backend"
check_dir "backend/config"
check_dir "backend/db"
check_dir "client"
check_dir "client/src"
check_dir "client/public"
check_dir "scripts"

log_info "Project validation completed."

log_info "Deployment completed successfully!"
