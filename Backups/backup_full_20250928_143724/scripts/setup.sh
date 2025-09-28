#!/bin/bash
echo "Setting up AI Chatbot project..."

# Check for Ollama
if ! command -v ollama &> /dev/null; then
    echo "Warning: Ollama not found. Please install from https://ollama.ai/"
fi

# Create data directories
mkdir -p backend/db backend/vectorstore backend/logs data

echo "Setup complete!"
