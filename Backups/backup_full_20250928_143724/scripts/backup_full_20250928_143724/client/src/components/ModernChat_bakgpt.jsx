import React, { useState, useRef } from 'react'
import { useChat } from '../hooks/useChat'
import { chatService } from '../services/chatService'

const ModernChat = () => {
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);
  const [input, setInput] = useState('')
  const messagesEndRef = useRef(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);
  const [isDragging, setIsDragging] = useState(false)
  const messagesEndRef = useRef(null)
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
      <div className="flex-1 overflow-y-auto p-4 space-y-4 scrollbar scrollbar-thumb-gray-600 scrollbar-track-gray-800">
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
