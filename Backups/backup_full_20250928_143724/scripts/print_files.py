#!/usr/bin/env python3
import os
import glob

def print_important_files():
    base_dir = "chatbotai_clean_20250922_184733"
    
    # Define important files with their categories
    important_files = {
        "Backend Core": [
            "backend/server.js",
            "backend/auth.js", 
            "backend/db.js",
            "backend/rag.js",
            "backend/memory.js",
            "backend/ws-server.js"
        ],
        "Configuration": [
            "backend/config/*",
            "package.json",
            "client/package.json",
            "docker-compose.yml",
            "Dockerfile"
        ],
        "Frontend Core": [
            "client/src/**/*.js",
            "client/src/**/*.jsx", 
            "client/src/**/*.ts",
            "client/src/**/*.tsx",
            "client/src/**/*.css",
            "client/src/**/*.scss",
            "client/index.html",
            "client/vite.config.js",
            "client/tailwind.config.js"
        ],
        "Backend Utils": [
            "backend/utils/*.js",
            "backend/middleware/*.js",
            "backend/vectorstore/*.js"
        ]
    }
    
    for category, files in important_files.items():
        print(f"\n{'='*80}")
        print(f"CATEGORY: {category}")
        print(f"{'='*80}")
        
        for file_pattern in files:
            # Handle wildcard patterns with recursion
            if '**' in file_pattern:
                # Recursive glob
                full_pattern = os.path.join(base_dir, file_pattern)
                matched_files = glob.glob(full_pattern, recursive=True)
                for matched_file in matched_files:
                    if os.path.isfile(matched_file):
                        print_file_content(matched_file)
            elif '*' in file_pattern:
                # Non-recursive glob
                full_pattern = os.path.join(base_dir, file_pattern)
                matched_files = glob.glob(full_pattern)
                for matched_file in matched_files:
                    if os.path.isfile(matched_file):
                        print_file_content(matched_file)
            else:
                file_path = os.path.join(base_dir, file_pattern)
                if os.path.isfile(file_path):
                    print_file_content(file_path)

def print_file_content(file_path):
    if os.path.exists(file_path):
        print(f"\n{'─'*60}")
        print(f"FILE: {file_path}")
        print(f"{'─'*60}")
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                print(content)
        except UnicodeDecodeError:
            try:
                with open(file_path, 'r', encoding='latin-1') as f:
                    content = f.read()
                    print(content)
            except Exception as e:
                print(f"Error reading file: {e}")
        except Exception as e:
            print(f"Error: {e}")
    else:
        print(f"\n⚠️  File not found: {file_path}")

if __name__ == "__main__":
    print_important_files()
