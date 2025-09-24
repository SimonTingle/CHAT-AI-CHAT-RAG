const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Import modules
const { saveMemory, getMemory } = require('./memory');
const { initDB, saveMessage, getChatHistory } = require('./db');
const { initVectorStore, queryVectorStore, addDocument, getVectorStoreStats } = require('./rag');
const { authenticateUser } = require('./auth');

const app = express();
const PORT = process.env.PORT || 3000;
const http = require('http');
const { startWs } = require('./ws-server');

// Configuration
const LOG_DIR = path.join(__dirname, 'logs');
if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Initialize databases
initDB();
let vectorStore;
(async () => {
  try {
    vectorStore = await initVectorStore();
    console.log('✅ Vector store initialized');
  } catch (error) {
    console.error('❌ Vector store initialization failed:', error);
  }
})();

// Enhanced safe response handler
function safeJson(res, status, payload) {
  if (!res.headersSent) {
    res.status(status).json(payload);
  } else {
    console.warn('⚠️ Attempted to send response after headers were sent');
  }
}

// HEALTH CHECK
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '2.0.0'
  });
});

// CHAT ENDPOINT (FIXED)
app.post('/chat', authenticateUser, async (req, res) => {
  try {
    const { prompt, userId = 'default' } = req.body;
    
    if (!prompt || typeof prompt !== 'string') {
      return safeJson(res, 400, { error: 'Invalid prompt' });
    }

    // Load memory and history
    const memoryFacts = await getMemory(userId).catch(() => []);
    const history = await getChatHistory(userId).catch(() => []);
    
    // RAG context
    const context = await queryVectorStore(prompt, vectorStore).catch(() => '');
    
    // Build prompt with memory and context
    const memoryContext = memoryFacts.map(f => `${f.key}: ${f.value}`).join('\n');
    const fullPrompt = `Known facts:\n${memoryContext}\n\nContext: ${context}\nUser: ${prompt}`;

    // Save user message
    await saveMessage(userId, 'user', prompt).catch(console.error);

    // Prepare messages for Ollama - USING GENERATE API FORMAT
    let systemPrompt = '';
    try {
      const memMap = {};
      if (Array.isArray(memoryFacts)) {
        for (const f of memoryFacts) memMap[f.key] = f.value;
      }
      if (memMap.name) systemPrompt = `You are talking to ${memMap.name}.`;
    } catch (e) {
      console.warn('Failed to construct systemPrompt from memory:', e);
    }

    // Build the final prompt for the generate API
    let finalPrompt = '';
    if (systemPrompt) finalPrompt += systemPrompt + '\n\n';
    
    // Add history
    if (history.length > 0) {
      history.forEach(msg => {
        finalPrompt += `${msg.role}: ${msg.content}\n`;
      });
    }
    
    finalPrompt += `User: ${fullPrompt}\nAssistant:`;

    // Enhanced Ollama call with better error handling
    let aiResponse = 'Sorry, I encountered an error. Please try again.';

    try {
      console.log('📤 Sending to Ollama with model:', process.env.OLLAMA_MODEL);
      
      const response = await fetch('http://localhost:11434/api/generate', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          model: process.env.OLLAMA_MODEL || 'mistral:7b', // Default to mistral
          prompt: finalPrompt,
          stream: false,
          options: {
            temperature: 0.7,
            top_p: 0.9,
          }
        }),
        timeout: 30000
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('❌ Ollama request failed:', response.status, errorText);
        throw new Error(`Ollama request failed: ${response.status} ${errorText}`);
      }
      
      const data = await response.json();
      aiResponse = data.response || '[No response from model]';
      console.log('✅ Ollama response received');

    } catch (error) {
      console.error('❌ Ollama communication error:', error.message);
      // Fallback to a simple response
      aiResponse = 'I apologize, but I am having trouble connecting to the AI service. Please check if Ollama is running.';
    }

    // Save AI response
    await saveMessage(userId, 'assistant', aiResponse).catch(console.error);

    // Log chat
    fs.appendFileSync(
      path.join(LOG_DIR, 'chat.log'),
      `[${new Date().toISOString()}] User ${userId}: ${prompt} -> ${aiResponse}\n`
    );

    safeJson(res, 200, { reply: aiResponse });
  } catch (error) {
    console.error('Chat error:', error);
    safeJson(res, 500, { error: 'Chat failed' });
  }
}); // <-- THIS WAS MISSING!

// DOCUMENT UPLOAD ENDPOINT
app.post('/api/documents', authenticateUser, async (req, res) => {
  try {
    const { text, metadata = {}, userId } = req.body;
    
    if (!text || typeof text !== 'string') {
      return safeJson(res, 400, { error: 'Invalid document text' });
    }

    // Check if vector store is initialized
    if (!vectorStore) {
      return safeJson(res, 503, { error: 'Vector store not ready. Please try again in a moment.' });
    }

    const success = await addDocument(text, metadata, vectorStore);
    
    if (success) {
      // Log the document addition
      fs.appendFileSync(
        path.join(LOG_DIR, 'documents.log'),
        `[${new Date().toISOString()}] User ${userId} added: ${metadata?.fileName || 'unknown'}\n`
      );
      
      safeJson(res, 200, { 
        success: true, 
        message: 'Document added to knowledge base',
        documentId: metadata.fileName 
      });
    } else {
      safeJson(res, 500, { error: 'Failed to process document' });
    }
  } catch (error) {
    console.error('Document upload error:', error);
    safeJson(res, 500, { error: 'Document upload failed: ' + error.message });
  }
});

// RAG STATS ENDPOINT
app.get('/api/rag/stats', async (req, res) => {
  try {
    const stats = await getVectorStoreStats(vectorStore);
    safeJson(res, 200, stats);
  } catch (error) {
    safeJson(res, 500, { error: error.message });
  }
});

// Export logs endpoint
app.get('/export-logs', authenticateUser, (req, res) => {
  try {
    const logs = fs.readFileSync(path.join(LOG_DIR, 'chat.log'), 'utf8');
    res.json({ logs });
  } catch (error) {
    safeJson(res, 500, { error: 'Failed to read logs' });
  }
});

// Memory endpoints
app.post('/remember', authenticateUser, async (req, res) => {
  try {
    const { userId = 'default', key, value } = req.body;
    if (!key || value === undefined) return safeJson(res, 400, { error: 'Invalid key/value' });
    await saveMemory(userId, key, value);
    safeJson(res, 200, { message: `Remembered ${key}: ${value}` });
  } catch (error) {
    safeJson(res, 500, { error: 'Failed to remember' });
  }
});

app.get('/memory', authenticateUser, async (req, res) => {
  try {
    const userId = req.query.userId || 'default';
    const memory = await getMemory(userId);
    res.json({ memory });
  } catch (error) {
    safeJson(res, 500, { error: 'Failed to fetch memory' });
  }
});

// Create HTTP server with WebSocket support
const server = http.createServer(app);
const wss = startWs(server);

server.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
});