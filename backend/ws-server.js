const WebSocket = require('ws');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();
const fetch = require('node-fetch');

function startWs(server, options = {}) {
  const wss = new WebSocket.Server({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
    ws.isAlive = true;
    ws.on('pong', () => ws.isAlive = true);

    ws.on('message', async (raw) => {
      let msg;
      try { 
        msg = JSON.parse(raw); 
      } catch (e) { 
        return ws.send(JSON.stringify({ type: 'error', message: 'invalid json' })); 
      }

      if (msg.type === 'start') {
        const userId = msg.userId || 'default';
        const prompt = msg.prompt || '';
        const callId = msg.id || `c_${Date.now()}`;

        // Acknowledge request
        ws.send(JSON.stringify({ type: 'ack', id: callId }));

        try {
          const response = await fetch('http://localhost:11434/api/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
              model: process.env.OLLAMA_MODEL || 'llama3.1:8b', 
              messages: [{ role: 'user', content: prompt }] 
            })
          });

          const text = await response.text();
          const lines = text.split(/\r?\n/).filter(Boolean);
          let assembled = '';
          
          for (const line of lines) {
            try {
              const parsed = JSON.parse(line);
              const token = parsed?.message?.content || parsed?.content || '';
              if (token) {
                assembled += token;
                ws.send(JSON.stringify({ type: 'delta', id: callId, delta: token }));
              }
            } catch (e) {
              // Ignore non-JSON lines
            }
          }

          const finalText = assembled || '[No response from model]';
          ws.send(JSON.stringify({ type: 'done', id: callId, text: finalText }));

          // Persist message
          const db = new sqlite3.Database(path.join(__dirname, 'db', 'chat.db'));
          db.run("INSERT INTO chats(user_id, role, message) VALUES(?, ?, ?)", 
            [userId, 'assistant', finalText], 
            (err) => {
              if (err) console.error('Failed to persist message:', err);
              db.close();
            }
          );

        } catch (error) {
          ws.send(JSON.stringify({ type: 'error', id: callId, message: 'Model call failed' }));
        }
      }
    });

    ws.on('close', () => {
      console.log('WebSocket connection closed');
    });
  });

  // Heartbeat
  const interval = setInterval(() => {
    wss.clients.forEach((ws) => {
      if (!ws.isAlive) return ws.terminate();
      ws.isAlive = false;
      ws.ping();
    });
  }, options.heartbeatInterval || 30000);

  wss.on('close', () => clearInterval(interval));
  return wss;
}

module.exports = { startWs };
