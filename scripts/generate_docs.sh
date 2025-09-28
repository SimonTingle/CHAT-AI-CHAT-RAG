#!/bin/bash

# Get project info
PROJECT_NAME=$(basename "$(pwd)")
FILES=$(find . -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.java" | head -20)

echo "Analyzing project: $PROJECT_NAME"

# Create prompt with project context
PROMPT="Project: $PROJECT_NAME

Files found:
$FILES

Please analyze this project and:
1. Identify missing documentation (README.md, CONTRIBUTING.md, LICENSE, etc.)
2. Generate complete content for each missing documentation file
3. Include proper formatting and structure

Provide the documentation content ready to be saved to files."

# Send to Ollama
ollama run mistral "$PROMPT"

