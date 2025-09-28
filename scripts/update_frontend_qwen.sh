#!/bin/bash

# update_frontend_qwen.sh
echo "🚀 Updating frontend with Qwen Chatbot integration..."

# Create services directory if it doesn't exist
mkdir -p src/services src/hooks src/components src/utils

# Create API service
cat > src/services/api.js << 'EOF'
import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3001',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

api.interceptors.request.use(
  (config) => {
    // Add userId to all requests
    const userId = localStorage.getItem('userId') || 'default-user'
    if (config.method === 'post' || config.method === 'get') {
      if (config.method === 'post') {
        config.data = { ...config.data, userId }
      } else {
        config.params = { ...config.params, userId }
      }
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message)
    return Promise.reject(error)
  }
)

export default api
EOF

# Create chat service
cat > src/services/chatService.js << 'EOF'
import api from './api'

export const chatService = {
  sendMessage: async (prompt, userId = 'default-user') => {
    try {
      const response = await api.post('/chat', { prompt, userId })
      return response.data
    } catch (error) {
      throw new Error(error.response?.data?.error || 'Failed to send message')
    }
  },

  uploadDocument: async (text, metadata = {}, userId = 'default-user') => {
    try {
      const response = await api.post('/api/documents', { text, metadata, userId })
      return response.data
    } catch (error) {
      throw new Error(error.response?.data?.error || 'Failed to upload document')
    }
  },

  getRagStats: async () => {
    try {
      const response = await api.get('/api/rag/stats')
      return response.data
    } catch (error) {
      throw new Error(error.response?.data?.error || 'Failed to get RAG stats')
    }
  },

  saveMemory: async (key, value, userId = 'default-user') => {
    try {
      const response = await api.post('/remember', { key, value, userId })
      return response.data
    } catch (error) {
      throw new Error(error.response?.data?.error || 'Failed to save memory')
    }
  },

  getMemory: async (userId = 'default-user') => {
    try {
      const response = await api.get('/memory', { params: { userId } })
      return response.data.memory || []
    } catch (error) {
      throw new Error(error.response?.data?.error || 'Failed to get memory')
    }
  },

  healthCheck: async () => {
    try {
      const response = await api.get('/health')
      return response.data
    } catch (error) {
      throw new Error('Server health check failed')
    }
  },

  ollamaHealthCheck: async () => {
    try {
      const response = await api.get('/api/ollama/health')
      return response.data
    } catch (error) {
      throw new Error('Ollama health check failed')
    }
  }
}
EOF

# Create useChat hook
cat > src/hooks/useChat.js << 'EOF'
import { useState, useCallback } from 'react'
import { chatService } from '../services/chatService'

export const useChat = () => {
  const [messages, setMessages] = useState([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)

  const sendMessage = useCallback(async (prompt, userId = 'default-user') => {
    if (!prompt?.trim()) return

    try {
      setIsLoading(true)
      setError(null)

      const userMessage = {
        id: Date.now(),
        role: 'user',
        content: prompt,
        timestamp: new Date().toISOString()
      }
      
      setMessages(prev => [...prev, userMessage])

      const response = await chatService.sendMessage(prompt, userId)
      
      const aiMessage = {
        id: Date.now() + 1,
        role: 'assistant',
        content: response.reply,
        timestamp: new Date().toISOString(),
        responseTime: response.responseTime
      }
      
      setMessages(prev => [...prev, aiMessage])
      
      return response
    } catch (err) {
      setError(err.message)
      const errorMessage = {
        id: Date.now() + 2,
        role: 'error',
        content: `Error: ${err.message}`,
        timestamp: new Date().toISOString()
      }
      setMessages(prev => [...prev, errorMessage])
      throw err
    } finally {
      setIsLoading(false)
    }
  }, [])

  const clearChat = useCallback(() => {
    setMessages([])
    setError(null)
  }, [])

  const addDocument = useCallback(async (text, metadata = {}, userId = 'default-user') => {
    try {
      setIsLoading(true)
      setError(null)
      const response = await chatService.uploadDocument(text, metadata, userId)
      return response
    } catch (err) {
      setError(err.message)
      throw err
    } finally {
      setIsLoading(false)
    }
  }, [])

  return {
    messages,
    isLoading,
    error,
    sendMessage,
    clearChat,
    addDocument,
    setMessages
  }
}
EOF

# Create modern dark-themed chat component with drag & drop
cat > src/components/ModernChat.jsx << 'EOF'
import React, { useState, useRef } from 'react'
import { useChat } from '../hooks/useChat'
import { chatService } from '../services/chatService'

const ModernChat = () => {
  const [input, setInput] = useState('')
  const [isDragging, setIsDragging] = useState(false)
  const [documentStatus, setDocumentStatus] = useState('')
  const [ragStats, setRagStats] = useState(null)
  const [showRagStats, setShowRagStats] = useState(false)
  const fileInputRef = useRef(null)
  
  const { messages, isLoading, error, sendMessage, clearChat, addDocument } = useChat()

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!input.trim() || isLoading) return
    
    try {
      await sendMessage(input)
      setInput('')
    } catch (err) {
      console.error('Failed to send message:', err)
    }
  }

  const handleHealthCheck = async () => {
    try {
      const [health, ollama] = await Promise.all([
        chatService.healthCheck(),
        chatService.ollamaHealthCheck()
      ])
      alert(`Server: OK\nOllama: ${ollama.status === 'ok' ? 'Connected' : 'Disconnected'}`)
    } catch (err) {
      alert('Health check failed: ' + err.message)
    }
  }

  const handleRagStats = async () => {
    try {
      const stats = await chatService.getRagStats()
      setRagStats(stats)
      setShowRagStats(true)
    } catch (err) {
      alert('Failed to get RAG stats: ' + err.message)
    }
  }

  const handleDragOver = (e) => {
    e.preventDefault()
    setIsDragging(true)
  }

  const handleDragLeave = (e) => {
    e.preventDefault()
    setIsDragging(false)
  }

  const handleDrop = async (e) => {
    e.preventDefault()
    setIsDragging(false)
    
    const files = Array.from(e.dataTransfer.files)
    if (files.length === 0) return

    await processFiles(files)
  }

  const handleFileSelect = async (e) => {
    const files = Array.from(e.target.files)
    if (files.length === 0) return

    await processFiles(files)
    e.target.value = '' // Reset input
  }

  const processFiles = async (files) => {
    setDocumentStatus('Processing documents...')
    
    try {
      for (const file of files) {
        if (file.type.startsWith('text/') || file.name.endsWith('.txt') || file.name.endsWith('.md')) {
          const text = await file.text()
          const metadata = {
            fileName: file.name,
            fileSize: file.size,
            fileType: file.type,
            lastModified: new Date(file.lastModified).toISOString()
          }
          
          await addDocument(text, metadata)
          setDocumentStatus(`✅ Processed: ${file.name}`)
        } else {
          setDocumentStatus(`❌ Unsupported file type: ${file.name}`)
        }
      }
      
      setTimeout(() => setDocumentStatus(''), 3000)
    } catch (err) {
      setDocumentStatus(`❌ Error: ${err.message}`)
      setTimeout(() => setDocumentStatus(''), 5000)
    }
  }

  const formatMessageContent = (content) => {
    return content.split('\n').map((line, i) => (
      <React.Fragment key={i}>
        {line}
        <br />
      </React.Fragment>
    ))
  }

  return (
    <div className="flex flex-col h-screen bg-gray-900 text-gray-100">
      {/* Header */}
      <div className="bg-gray-800 border-b border-gray-700 p-4 flex justify-between items-center shadow-lg">
        <div className="flex items-center space-x-3">
          <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
          <h1 className="text-xl font-bold bg-gradient-to-r from-blue-400 to-purple-500 bg-clip-text text-transparent">
            AI Chat Assistant
          </h1>
        </div>
        <div className="flex space-x-2">
          <button 
            onClick={handleRagStats}
            className="bg-gray-700 hover:bg-gray-600 px-3 py-1 rounded-lg text-sm transition-all duration-200 shadow-md hover:shadow-lg"
          >
            RAG Stats
          </button>
          <button 
            onClick={handleHealthCheck}
            className="bg-blue-600 hover:bg-blue-500 px-3 py-1 rounded-lg text-sm transition-all duration-200 shadow-md hover:shadow-lg"
          >
            Health
          </button>
        </div>
      </div>

      {/* RAG Stats Modal */}
      {showRagStats && ragStats && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-gray-800 rounded-xl p-6 max-w-md w-full shadow-2xl border border-gray-700">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-bold">RAG Statistics</h3>
              <button 
                onClick={() => setShowRagStats(false)}
                className="text-gray-400 hover:text-white"
              >
                ✕
              </button>
            </div>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-400">Documents:</span>
                <span className="font-mono">{ragStats.documentCount || 0}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Vectors:</span>
                <span className="font-mono">{ragStats.vectorCount || 0}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Dimensions:</span>
                <span className="font-mono">{ragStats.dimensions || 0}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Document Status */}
      {documentStatus && (
        <div className="bg-gray-800 border-b border-gray-700 px-4 py-2 text-center text-sm">
          {documentStatus}
        </div>
      )}

      {/* Drag & Drop Area */}
      <div 
        className={`m-4 rounded-xl border-2 border-dashed p-8 text-center transition-all duration-300 ${
          isDragging 
            ? 'border-blue-500 bg-blue-900 bg-opacity-20' 
            : 'border-gray-600 hover:border-gray-500'
        }`}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
      >
        <div className="space-y-2">
          <div className="text-2xl">📁</div>
          <p className="text-gray-300">
            <span className="text-blue-400 font-medium">Drag & drop</span> files here or click to browse
          </p>
          <p className="text-gray-500 text-sm">Supports .txt and .md files</p>
        </div>
        <input
          type="file"
          ref={fileInputRef}
          className="hidden"
          multiple
          accept=".txt,.md,text/*"
          onChange={handleFileSelect}
        />
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 scrollbar-thin scrollbar-thumb-gray-600 scrollbar-track-gray-800">
        {messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-gray-500">
            <div className="text-4xl mb-4">🤖</div>
            <p>Start a conversation or drop documents to enhance knowledge</p>
          </div>
        ) : (
          messages.map((message) => (
            <div
              key={message.id}
              className={`p-4 rounded-2xl max-w-4xl mx-auto transition-all duration-300 ${
                message.role === 'user'
                  ? 'bg-gradient-to-r from-blue-900 to-blue-800 ml-auto shadow-lg shadow-blue-900/30 border border-blue-700'
                  : message.role === 'assistant'
                  ? 'bg-gradient-to-r from-gray-800 to-gray-700 shadow-lg shadow-gray-900/30 border border-gray-600'
                  : 'bg-gradient-to-r from-red-900 to-red-800 shadow-lg shadow-red-900/30 border border-red-700'
              }`}
            >
              <div className="flex items-start space-x-3">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold ${
                  message.role === 'user' 
                    ? 'bg-blue-600' 
                    : message.role === 'assistant' 
                    ? 'bg-purple-600' 
                    : 'bg-red-600'
                }`}>
                  {message.role === 'user' ? '👤' : message.role === 'assistant' ? '🤖' : '⚠️'}
                </div>
                <div className="flex-1">
                  <div className="font-semibold capitalize flex items-center space-x-2">
                    <span>{message.role === 'user' ? 'You' : message.role === 'assistant' ? 'Assistant' : 'Error'}</span>
                    {message.responseTime && (
                      <span className="text-xs text-gray-400 bg-gray-700 px-2 py-1 rounded">
                        {message.responseTime}
                      </span>
                    )}
                  </div>
                  <div className="mt-2 text-gray-100 leading-relaxed">
                    {formatMessageContent(message.content)}
                  </div>
                  <div className="text-xs text-gray-400 mt-2">
                    {new Date(message.timestamp).toLocaleTimeString()}
                  </div>
                </div>
              </div>
            </div>
          ))
        )}
        
        {isLoading && (
          <div className="p-4 rounded-2xl max-w-4xl mx-auto bg-gradient-to-r from-gray-800 to-gray-700 shadow-lg shadow-gray-900/30 border border-gray-600">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 rounded-full bg-purple-600 flex items-center justify-center">
                🤖
              </div>
              <div className="flex space-x-1">
                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.1s'}}></div>
                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.2s'}}></div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Error */}
      {error && (
        <div className="mx-4 mb-4 p-3 bg-red-900 border border-red-700 rounded-xl text-red-200 text-sm">
          ⚠️ {error}
        </div>
      )}

      {/* Input */}
      <form onSubmit={handleSubmit} className="p-4 border-t border-gray-800">
        <div className="flex space-x-3 max-w-4xl mx-auto">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Message AI assistant..."
            className="flex-1 bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent placeholder-gray-500"
            disabled={isLoading}
          />
          <button
            type="submit"
            disabled={!input.trim() || isLoading}
            className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-500 hover:to-purple-500 text-white px-6 py-3 rounded-xl disabled:opacity-50 transition-all duration-200 shadow-lg hover:shadow-xl disabled:cursor-not-allowed"
          >
            {isLoading ? (
              <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
            ) : (
              'Send'
            )}
          </button>
          <button
            type="button"
            onClick={clearChat}
            className="bg-gray-700 hover:bg-gray-600 text-gray-200 px-4 py-3 rounded-xl transition-all duration-200 shadow-md hover:shadow-lg"
          >
            Clear
          </button>
        </div>
      </form>
    </div>
  )
}

export default ModernChat
EOF

# Update App.jsx to use the new component
cat > src/App.jsx << 'EOF'
import React from 'react'
import ModernChat from './components/ModernChat'
import './App.css'

function App() {
  return (
    <div className="App">
      <ModernChat />
    </div>
  )
}

export default App
EOF

# Update index.css for dark theme and styling
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  color-scheme: dark;
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #111827;
  color: #f9fafb;
  height: 100vh;
  overflow: hidden;
}

#root {
  height: 100vh;
}

/* Scrollbar styling */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: #1f2937;
}

::-webkit-scrollbar-thumb {
  background: #4b5563;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: #6b7280;
}

/* Custom animations */
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Custom shadows for dark theme */
.shadow-lg {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.3), 0 4px 6px -2px rgba(0, 0, 0, 0.2);
}

.shadow-xl {
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
}

.shadow-2xl {
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.4);
}
EOF

echo "✅ Frontend update completed successfully!"
echo "📋 Changes made:"
echo "  - Created API services for backend communication"
echo "  - Added modern dark-themed chat interface"
echo "  - Implemented drag & drop document processing"
echo "  - Added RAG statistics and health checks"
echo "  - Created reusable React hooks"
echo ""
echo "🚀 To use the new interface, make sure your App.jsx imports ModernChat"
echo "🔧 Don't forget to set VITE_API_BASE_URL in your .env file"
EOF

# Make the script executable
chmod +x update_frontend_qwen.sh

echo "✅ Update script created: update_frontend_qwen.sh"
echo " Run: ./update_frontend_qwen.sh to apply changes"

