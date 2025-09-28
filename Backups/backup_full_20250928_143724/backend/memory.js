const sqlite3 = require('sqlite3').verbose();
const path = require('path');

function normalize(x) {
  return String(x || '').trim();
}

function saveMemory(userId, key, value) {
  userId = normalize(userId);
  key = normalize(key);
  value = normalize(value);

  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(path.join(__dirname, 'db', 'chat.db'));
    db.run(
      `INSERT INTO memory (userId, key, value, timestamp)
       VALUES (?, ?, ?, CURRENT_TIMESTAMP)
       ON CONFLICT(userId, key) DO UPDATE SET
         value=excluded.value,
         timestamp=CURRENT_TIMESTAMP`,
      [userId, key, value],
      function (err) {
        db.close();
        if (err) {
          console.error('saveMemory error:', err);
          return reject(err);
        }
        resolve({ changes: this.changes });
      }
    );
  });
}

function getMemory(userId) {
  userId = normalize(userId);
  return new Promise((resolve) => {
    const db = new sqlite3.Database(path.join(__dirname, 'db', 'chat.db'));
    db.all('SELECT key, value FROM memory WHERE userId = ?', [userId], (err, rows) => {
      db.close();
      if (err) {
        console.error('getMemory error:', err);
        return resolve([]);
      }
      resolve(rows || []);
    });
  });
}

module.exports = { saveMemory, getMemory };
