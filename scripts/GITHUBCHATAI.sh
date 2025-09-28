#!/bin/bash

# GITHUBCHATAI.sh - Simple GitHub upload preparation
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "backend" ] || [ ! -d "client" ]; then
    log_error "Run this from your project root: chatbotai_clean_20250922_184733"
    exit 1
fi

# Check essential files
log_info "Checking essential files..."
essential_files=(
    "package.json"
    "backend/server.js"
    "backend/rag.js" 
    "backend/db.js"
    "backend/memory.js"
    "backend/auth.js"
    "backend/ws-server.js"
    "client/src/App.jsx"
    "client/src/index.jsx"
    "client/index.html"
    "client/vite.config.js"
)

missing_files=()
for file in "${essential_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file"
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -ne 0 ]; then
    log_error "Missing essential files. Cannot proceed."
    exit 1
fi

# Create minimal .gitignore if missing
if [ ! -f ".gitignore" ]; then
    log_warn "Creating .gitignore..."
    cat > .gitignore << 'EOF'
node_modules/
backend/node_modules/
client/node_modules/
backend/db/*.db
backend/vectorstore/data/
backend/logs/
.env
.DS_Store
EOF
fi

# Initialize git if needed
if [ ! -d ".git" ]; then
    log_info "Initializing git repository..."
    git init
    git branch -M main
fi

# Show what will be committed
log_info "Files to be committed:"
git status --short

# Ask for commit
read -p "Create initial commit? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add .
    git commit -m "Initial commit: AI Chatbot with RAG and Memory"
    log_info "Commit created!"
    echo
    echo "Next steps:"
    echo "1. Create repo at https://github.com/new"
    echo "2. Run: git remote add origin YOUR_REPO_URL"
    echo "3. Run: git push -u origin main"
else
    log_info "No commit created. You can manually run:"
    echo "git add . && git commit -m 'Your message'"
fi