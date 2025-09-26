#!/bin/bash

echo "🚀 Starting client code update and verification..."

# Pre-check: Verify we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "src" ]; then
    echo "❌ Error: This script must be run from the client directory"
    echo "Current directory: $(pwd)"
    echo "Please navigate to your client directory and try again"
    exit 1
fi

# Pre-check: Verify required files exist
REQUIRED_FILES=("vite.config.js" "package.json" "tailwind.config.js")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Error: Required file $file not found"
        exit 1
    fi
done

echo "✅ Pre-checks passed"

# Create backup directory
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📋 Creating backups..."
# Backup existing files
cp vite.config.js "$BACKUP_DIR/vite.config.js.backup" 2>/dev/null || echo "No vite.config.js to backup"
cp src/App.jsx "$BACKUP_DIR/App.jsx.backup" 2>/dev/null || echo "No App.jsx to backup"
cp src/main.jsx "$BACKUP_DIR/main.jsx.backup" 2>/dev/null || echo "No main.jsx to backup"
cp src/index.css "$BACKUP_DIR/index.css.backup" 2>/dev/null || echo "No index.css to backup"

# Update vite.config.js
echo "🔧 Updating vite.config.js..."
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    hmr: {
      host: 'localhost',
      port: 5173,
      protocol: 'ws'
    },
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true
      },
      '/chat': {
        target: 'http://localhost:3001',
        changeOrigin: true
      }
    }
  }
})
EOF

# Update src/App.jsx
echo "🔧 Updating src/App.jsx..."
cat > src/App.jsx << 'EOF'
import React, { useState, useRef, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [userId] = useState('user_' + Math.random().toString(36).substr(2, 9));
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async (e) => {
    e.preventDefault();
    if (!inputValue.trim() || isLoading) return;

    const userMessage = { 
      id: Date.now(), 
      text: inputValue, 
      sender: 'user',
      timestamp: new Date().toLocaleTimeString()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputValue('');
    setIsLoading(true);

    try {
      const response = await axios.post('/chat', {
        prompt: inputValue,
        userId: userId
      });

      const aiMessage = {
        id: Date.now() + 1,
        text: response.data.reply,
        sender: 'ai',
        timestamp: new Date().toLocaleTimeString()
      };

      setMessages(prev => [...prev, aiMessage]);
    } catch (error) {
      console.error('Error sending message:', error);
      const errorMessage = {
        id: Date.now() + 1,
        text: 'Sorry, I encountered an error. Please try again.',
        sender: 'ai',
        timestamp: new Date().toLocaleTimeString(),
        error: true
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const clearChat = () => {
    setMessages([]);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex flex-col">
      {/* Header */}
      <header className="bg-white shadow-sm py-4 px-6">
        <div className="max-w-4xl mx-auto flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-800">AI Chatbot by Simon Tingle</h1>
          <button 
            onClick={clearChat}
            className="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors flex items-center gap-2"
          >
            🗑️ Clear Chat
          </button>
        </div>
      </header>

      {/* Chat Container */}
      <main className="flex-1 max-w-4xl mx-auto w-full p-4 flex flex-col">
        <div className="bg-white rounded-xl shadow-lg flex-1 flex flex-col">
          {/* Messages Area */}
          <div className="flex-1 p-4 overflow-y-auto max-h-[60vh]">
            {messages.length === 0 ? (
              <div className="text-center text-gray-500 mt-8">
                <p className="text-lg">Welcome to the AI Chatbot!</p>
                <p className="text-sm mt-2">Type a message below to start chatting.</p>
              </div>
            ) : (
              <div className="space-y-4">
                {messages.map((message) => (
                  <div
                    key={message.id}
                    className={`flex ${message.sender === 'user' ? 'justify-end' : 'justify-start'}`}
                  >
                    <div
                      className={`max-w-xs md:max-w-md lg:max-w-lg px-4 py-3 rounded-2xl ${
                        message.sender === 'user'
                          ? 'bg-blue-500 text-white rounded-br-none'
                          : message.error
                          ? 'bg-red-100 text-red-800 border border-red-200 rounded-bl-none'
                          : 'bg-gray-100 text-gray-800 rounded-bl-none'
                      }`}
                    >
                      <p className="whitespace-pre-wrap">{message.text}</p>
                      <p className="text-xs opacity-70 mt-1">{message.timestamp}</p>
                    </div>
                  </div>
                ))}
                {isLoading && (
                  <div className="flex justify-start">
                    <div className="bg-gray-100 text-gray-800 px-4 py-3 rounded-2xl rounded-bl-none">
                      <div className="flex space-x-2">
                        <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                        <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.2s'}}></div>
                        <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.4s'}}></div>
                      </div>
                    </div>
                  </div>
                )}
                <div ref={messagesEndRef} />
              </div>
            )}
          </div>

          {/* Input Area */}
          <div className="border-t p-4">
            <form onSubmit={handleSend} className="flex gap-2">
              <input
                type="text"
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                placeholder="Type your message..."
                className="flex-1 border border-gray-300 rounded-full px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
                disabled={isLoading}
              />
              <button
                type="submit"
                disabled={!inputValue.trim() || isLoading}
                className="bg-blue-500 text-white rounded-full px-6 py-3 hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
              >
                {isLoading ? '📤' : 'Send'}
              </button>
            </form>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="py-4 text-center text-gray-600 text-sm">
        <p>User ID: {userId}</p>
      </footer>
    </div>
  );
}

export default App;
EOF

# Update src/main.jsx
echo "🔧 Updating src/main.jsx..."
cat > src/main.jsx << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.jsx';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
EOF

# Update src/index.css
echo "🔧 Updating src/index.css..."
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f8fafc;
}

* {
  box-sizing: border-box;
}

/* Scrollbar styling */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f1f1;
}

::-webkit-scrollbar-thumb {
  background: #c5c5c5;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: #a0a0a0;
}
EOF

# Create src/App.css if it doesn't exist
echo "🔧 Creating/updating src/App.css..."
cat > src/App.css << 'EOF'
/* App specific styles */
.animate-bounce {
  animation: bounce 1s infinite;
}

@keyframes bounce {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-5px);
  }
}
EOF

# Post-checks
echo "🔍 Running post-checks..."

# Check if files were created successfully
FILES_TO_CHECK=(
    "vite.config.js"
    "src/App.jsx"
    "src/main.jsx"
    "src/index.css"
    "src/App.css"
)

echo "✅ File creation verification:"
for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file exists ($(wc -l < "$file" | tr -d ' ') lines)"
    else
        echo "  ❌ $file missing"
        exit 1
    fi
done

# Check file syntax/content
echo "✅ Content verification:"
if grep -q "target: 'http://localhost:3001'" vite.config.js; then
    echo "  ✅ Vite proxy configuration correct"
else
    echo "  ❌ Vite proxy configuration incorrect"
fi

if grep -q "import React, { useState" src/App.jsx; then
    echo "  ✅ App.jsx has proper React imports"
else
    echo "  ❌ App.jsx missing React imports"
fi

if grep -q "@tailwind" src/index.css; then
    echo "  ✅ Tailwind CSS properly configured"
else
    echo "  ❌ Tailwind CSS not properly configured"
fi

# Check for required dependencies
echo "✅ Dependency verification:"
REQUIRED_DEPS=("axios" "react" "react-dom" "tailwindcss" "autoprefixer" "postcss")
for dep in "${REQUIRED_DEPS[@]}"; do
    if npm list "$dep" >/dev/null 2>&1; then
        echo "  ✅ $dep installed"
    else
        echo "  ⚠️  $dep not found (installing...)"
        npm install "$dep" --save 2>/dev/null || echo "    Failed to install $dep"
    fi
done

# Verify package.json has correct scripts
if grep -q '"dev": "vite"' package.json; then
    echo "  ✅ Package.json has correct dev script"
else
    echo "  ⚠️  Package.json dev script may need update"
fi

echo "✅ Update complete!"
echo "📋 Backup files saved in: $BACKUP_DIR"
echo ""
echo "🚀 To test the updated client:"
echo "   1. Make sure your backend is running on port 3001"
echo "   2. Run: npm run dev"
echo "   3. Visit: http://localhost:5173"
echo ""
echo "🔧 If you encounter issues, you can restore from backup:"
echo "   cp $BACKUP_DIR/* . 2>/dev/null || echo 'No backup files to restore'"

