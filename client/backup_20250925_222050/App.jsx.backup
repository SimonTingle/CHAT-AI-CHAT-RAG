import { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import './index.css';

function App() {
  // State declarations
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [userId, setUserId] = useState('');
  const [isDragging, setIsDragging] = useState(false);
  const [uploadStatus, setUploadStatus] = useState('');
  
  const fileInputRef = useRef(null);

  // Effects
  useEffect(() => {
    const storedUserId = localStorage.getItem('chatUserId');
    if (storedUserId) {
      setUserId(storedUserId);
    } else {
      const newUserId = 'user_' + Math.random().toString(36).substring(2, 9);
      setUserId(newUserId);
      localStorage.setItem('chatUserId', newUserId);
    }
  }, []);

  // Event handlers
  const handleSendMessage = async () => {
    if (!input.trim() || loading) return;
    
    const userMessage = { role: 'user', content: input };
    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setLoading(true);

    try {
      const response = await axios.post('http://localhost:3000/chat', {
        prompt: input,
        userId: userId
      });
      setMessages(prev => [...prev, { 
        role: 'assistant', 
        content: response.data.reply 
      }]);
    } catch (error) {
      console.error('Error sending message:', error);
      setMessages(prev => [...prev, { 
        role: 'assistant', 
        content: 'Sorry, I encountered an error. Please try again.' 
      }]);
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = async (file) => {
    if (!file) return;

    setUploadStatus('Reading document...');
    
    try {
      const text = await readFileContent(file);
      setUploadStatus('Adding to knowledge base...');

      const response = await axios.post('http://localhost:3000/api/documents', {
        text: text,
        metadata: {
          fileName: file.name,
          fileType: file.type,
          fileSize: file.size,
          uploadedAt: new Date().toISOString()
        },
        userId: userId
      });

      if (response.data.success) {
        setUploadStatus(`✅ "${file.name}" added successfully!`);
        setTimeout(() => setUploadStatus(''), 3000);
      } else {
        setUploadStatus('❌ Failed to add document');
      }
    } catch (error) {
      console.error('Upload error:', error);
      setUploadStatus('❌ Error uploading document');
    }
  };

  const readFileContent = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => resolve(e.target.result);
      reader.onerror = (error) => reject(error);
      reader.readAsText(file); // Start with text files only for simplicity
    });
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    setIsDragging(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setIsDragging(false);
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFileUpload(files[0]);
    }
  };

  const handleExportLogs = async () => {
    try {
      const response = await axios.get('http://localhost:3000/export-logs', { 
        headers: { 'x-user-id': userId } 
      });
      const blob = new Blob([response.data.logs], { type: 'text/plain' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `chat_logs_${userId}_${new Date().toISOString().split('T')[0]}.txt`;
      a.click();
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Error exporting logs:', error);
      alert('Failed to export logs');
    }
  };

  const handleClearChat = () => {
    setMessages([]);
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  // UI Components
  const DragDropArea = () => (
    <div className="mb-4">
      <div 
        className={`border-2 border-dashed rounded-lg p-4 text-center cursor-pointer transition-colors ${
          isDragging ? 'border-blue-400 bg-blue-900/20' : 'border-gray-600 hover:border-gray-400'
        }`}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
      >
        <input
          ref={fileInputRef}
          type="file"
          className="hidden"
          accept=".txt,.md"
          onChange={(e) => {
            if (e.target.files?.[0]) {
              handleFileUpload(e.target.files[0]);
            }
          }}
        />
        <p className="text-lg mb-1">📁 Add Knowledge Document</p>
        <p className="text-sm text-gray-400">Drag & drop or click to upload .txt files</p>
        {uploadStatus && (
          <p className={`text-sm mt-2 ${
            uploadStatus.includes('✅') ? 'text-green-400' : 'text-red-400'
          }`}>
            {uploadStatus}
          </p>
        )}
      </div>
    </div>
  );

  const MessageArea = () => (
    <div className="h-96 overflow-y-auto mb-4 p-4 bg-gray-700 rounded-lg">
      {messages.length === 0 && !loading ? (
        <div className="text-center text-gray-400 h-full flex items-center justify-center">
          <p>Start a conversation or upload a document to begin</p>
        </div>
      ) : (
        messages.map((msg, index) => (
          <div key={index} className={`mb-3 ${msg.role === 'user' ? 'text-right' : 'text-left'}`}>
            <span className={`inline-block max-w-[80%] p-3 rounded-lg ${
              msg.role === 'user' 
                ? 'bg-blue-600 text-white' 
                : 'bg-gray-600 text-gray-100'
            }`}>
              {msg.content}
            </span>
          </div>
        ))
      )}
      {loading && (
        <div className="text-left">
          <span className="inline-block p-3 rounded-lg bg-gray-600 text-gray-300">
            Thinking...
          </span>
        </div>
      )}
    </div>
  );

  const InputArea = () => (
    <div className="flex gap-2 mb-4">
      <input
        type="text"
        value={input}
        onChange={(e) => setInput(e.target.value)}
        onKeyPress={handleKeyPress}
        className="flex-1 p-3 rounded-lg bg-gray-600 text-white border-none focus:outline-none focus:ring-2 focus:ring-blue-500"
        placeholder="Type your message..."
        disabled={loading}
      />
      <button
        onClick={handleSendMessage}
        disabled={loading || !input.trim()}
        className="px-6 py-3 bg-blue-500 rounded-lg hover:bg-blue-600 transition disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {loading ? '⏳' : '📤'}
      </button>
    </div>
  );

  const ActionButtons = () => (
    <div className="flex gap-2 mb-4">
      <button
        onClick={handleClearChat}
        className="flex-1 px-4 py-2 bg-yellow-500 rounded-lg hover:bg-yellow-600 transition"
      >
        🗑️ Clear Chat
      </button>
      <button
        onClick={handleExportLogs}
        className="flex-1 px-4 py-2 bg-green-500 rounded-lg hover:bg-green-600 transition"
      >
        📊 Export Logs
      </button>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-900 text-white flex flex-col items-center p-4">
      <div className="w-full max-w-4xl bg-gray-800 rounded-lg shadow-lg p-6">
        <h1 className="text-3xl font-bold mb-6 text-center">AI Chatbot by Simon Tingle</h1>
        
        <DragDropArea />
        <MessageArea />
        <InputArea />
        <ActionButtons />
        
        <div className="text-center text-sm text-gray-400 border-t border-gray-700 pt-4">
          User ID: {userId}
        </div>
      </div>
    </div>
  );
}

export default App;