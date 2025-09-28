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
