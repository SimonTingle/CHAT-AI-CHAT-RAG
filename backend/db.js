const sqlite3 = require('sqlite3').verbose();
const path = require('path');

function initDB() {
  const dbPath = path.join(__dirname, 'db', 'chat.db');
  const db = new sqlite3.Database(dbPath);
  
  db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT,
      role TEXT,
      content TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      display_name TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS chats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT,
      role TEXT CHECK(role IN ('user','assistant','system')),
      message TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS memory (
      userId TEXT,
      key TEXT,
      value TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (userId, key)
    )`);

    // Create indexes for better performance
    db.run('CREATE INDEX IF NOT EXISTS idx_messages_userId ON messages(userId)');
    db.run('CREATE INDEX IF NOT EXISTS idx_chats_userId ON chats(user_id)');
    db.run('CREATE INDEX IF NOT EXISTS idx_memory_userId ON memory(userId)');
  });
  
  db.close();
  console.log('✅ Database initialized successfully');
}

function saveMessage(userId, role, content) {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(path.join(__dirname, 'db', 'chat.db'));
    db.run(
      'INSERT INTO messages (userId, role, content) VALUES (?, ?, ?)',
      [userId, role, content],
      function (err) {
        db.close();
        if (err) reject(err);
        else resolve();
      }
    );
  });
}

function getChatHistory(userId, limit = 50) {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(path.join(__dirname, 'db', 'chat.db'));
    db.all(
      'SELECT role, content FROM messages WHERE userId = ? ORDER BY timestamp ASC LIMIT ?',
      [userId, limit],
      (err, rows) => {
        db.close();
        if (err) return reject(err);
        resolve(rows || []);
      }
    );
  });
}

module.exports = { initDB, saveMessage, getChatHistory };
