const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');
const path = require('path');
const fs = require('fs');
const http = require('http');
const socketIo = require('socket.io');
const dotenv = require('dotenv');

dotenv.config();

// Import modules (comment these out temporarily to test)
// const { saveMemory, getMemory } = require('./memory');
// const { initDB, saveMessage, getChatHistory } = require('./db');
// const { initVectorStore, queryVectorStore, addDocument, getVectorStoreStats } = require('./rag');
// const { authenticateUser } = require('./auth');
// const { startWs } = require('./ws-server');

// Simple authentication middleware for testing
const authenticateUser = (req, res, next) => {
    next();
};

// Configuration
const LOG_DIR = path.join(__dirname, 'logs');
if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });

// Initialize app and server
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "http://localhost:3000",
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Simple initialization
console.log('Initializing database...');
// For now, just log that we're initializing
const initDB = () => {
    console.log('Database initialized');
};

initDB();

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

// Simple test endpoint
app.get('/test', (req, res) => {
    res.json({ message: 'Server is running!' });
});

const PORT = process.env.PORT || 3001;

server.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
});
