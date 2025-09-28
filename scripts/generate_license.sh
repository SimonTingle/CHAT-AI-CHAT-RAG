#!/bin/bash
# Generate full documentation structure for CHAT-AI-CHAT-RAG
# Creates README.md (root), CONTRIBUTING.md, LICENSE, and ./docs with examples

set -euo pipefail

# --- Root level files ---
# Contributing guidelines
cat > CONTRIBUTING.md <<'EOF'
# Contributing to CHAT-AI-CHAT-RAG

We welcome contributions to improve this project.  

## Code Style
- Follow ESLint + Prettier defaults (or project configs if provided)
- Keep functions modular and documented with comments
- Use descriptive commit messages

## Pull Requests
1. Fork the repository
2. Create a new branch from `latest`
3. Make your changes with clear commit history
4. Submit a Pull Request and link related issues if applicable
EOF

# License
cat > LICENSE <<'EOF'
MIT License

Copyright (c) 2025 Simon Tingle (SimonTingle)

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included 
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.
EOF

# --- Docs folder ---
mkdir -p docs/images docs/examples

# Extended demo guide
cat > docs/README_demo.md <<'EOF'
# CHAT-AI-CHAT-RAG Demo & Usage Guide

This document expands on the main README with examples, screenshots, and workflows.

## Quick Demo
1. Start backend (`node server.js`)
2. Start frontend (`npm run dev`)
3. Upload a document
4. Ask a question (e.g., "Summarize this document in 3 points")

## Screenshots
- ![Home UI](images/demo-screenshot.png)
- ![Document Upload](images/document-upload.png)
- ![Conversation](images/conversation-example.png)

## Example Workflows
- Upload multiple research papers, then query differences
- Use for personal knowledge base (PDFs, notes, transcripts)
- Ask general queries without docs (falls back to LLM)

## Example Prompts
- “Summarize all documents in 5 bullet points”
- “Explain this concept like I’m a beginner”
- “Highlight contradictions between A and B”
EOF

# Prompt examples
cat > docs/examples/prompt-examples.md <<'EOF'
# Example Prompts for CHAT-AI-CHAT-RAG

- Summarization:
  > Summarize all uploaded documents in 5 bullet points

- Comparison:
  > Compare Document A and Document B. Highlight differences and similarities

- Explanation:
  > Explain this text as if I’m 12 years old

- Knowledge Extraction:
  > Extract all definitions of technical terms from these documents

- Cross-document Q&A:
  > What are the common themes across all uploaded PDFs?
EOF

# Sample chat
cat > docs/examples/sample-chat.md <<'EOF'
# Sample Chat Session

**User:** Uploads 2 PDFs (climate report + policy brief)

**Prompt:**  
"Compare the conclusions of these two documents and point out contradictions."

**Model Output:**  
- Document A: projects 1.5°C by 2035  
- Document B: projects 1.5°C by 2045  
- Both agree on mitigation policies  
- Contradiction: timing of warming threshold
EOF

# Architecture doc
cat > docs/architecture.md <<'EOF'
# System Architecture

## Tech Stack
- Frontend: React + Vite + MUI
- Backend: Node.js + Express
- Database: SQLite
- LLMs: Ollama (local) + Mistral

## Flow
1. User interacts with frontend (chat UI)
2. Backend handles API requests, document upload, and retrieval
3. SQLite stores chat logs and document references
4. Backend queries Ollama/Mistral with retrieved context
5. Response is streamed back to frontend
EOF

echo "✅ Documentation created: CONTRIBUTING.md, LICENSE, docs/"
