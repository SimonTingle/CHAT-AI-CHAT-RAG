// Simple DB functions
function initDB() {
    console.log('Database initialized');
}

async function saveMessage(userId, role, content) {
    console.log(`Saving message for ${userId}: ${role} - ${content}`);
}

async function getChatHistory(userId) {
    console.log(`Getting chat history for ${userId}`);
    return [];
}

module.exports = { initDB, saveMessage, getChatHistory };
