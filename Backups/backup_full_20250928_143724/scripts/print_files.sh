#!/bin/bash

BASE_DIR="chatbotai_clean_20250922_184733"

important_files=(
    "$BASE_DIR/backend/server.js"
    "$BASE_DIR/backend/auth.js"
    "$BASE_DIR/backend/db.js"
    "$BASE_DIR/backend/rag.js"
    "$BASE_DIR/backend/memory.js"
    "$BASE_DIR/backend/ws-server.js"
    "$BASE_DIR/package.json"
    "$BASE_DIR/client/package.json"
    "$BASE_DIR/docker-compose.yml"
    "$BASE_DIR/Dockerfile"
    "$BASE_DIR/client/vite.config.js"
    "$BASE_DIR/client/tailwind.config.js"
    "$BASE_DIR/client/index.html"
)

# Add all JS/JSX/TS/TSX/CSS/SCSS files from client/src recursively
while IFS= read -r -d '' file; do
    important_files+=("$file")
done < <(find "$BASE_DIR/client/src" -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.css" -o -name "*.scss" \) -print0)

# Add backend utility files
while IFS= read -r -d '' file; do
    important_files+=("$file")
done < <(find "$BASE_DIR/backend/utils" -type f -name "*.js" -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    important_files+=("$file")
done < <(find "$BASE_DIR/backend/middleware" -type f -name "*.js" -print0 2>/dev/null)

while IFS= read -r -d '' file; do
    important_files+=("$file")
done < <(find "$BASE_DIR/backend/vectorstore" -type f -name "*.js" -print0 2>/dev/null)

for file in "${important_files[@]}"; do
    if [ -f "$file" ]; then
        echo "===================================================================="
        echo "FILE: $file"
        echo "===================================================================="
        cat "$file"
        echo
        echo
    fi
done
