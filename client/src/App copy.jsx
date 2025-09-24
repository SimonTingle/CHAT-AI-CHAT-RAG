import { useState, useEffect } from 'react';
import axios from 'axios';
import './index.css';
import { useState, useRef } from 'react';


function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [userId, setUserId] = useState('');
  // Add this state near your other useState declarations
  const [isDragging, setIsDragging] = useState(false);
  const [uploadStatus, setUploadStatus] = useState('');

  // Keep your superior user ID persistence
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

  // Keep your better sendMessage function
  const sendMessage = async () => {
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
      setMessages(prev => [...prev, { role: 'assistant', content: response.data.reply }]);
    } catch (error) {
      console.error('Error:', error);
      setMessages(prev => [...prev, { 
        role: 'assistant', 
        content: 'Sorry, I encountered an error. Please try again.' 
      }]);
    } finally {
      setLoading(false);
    }
  };

  // Keep your better exportLogs function
  const exportLogs = async () => {
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

  // Add clear chat function (from your current version)
  const clearChat = () => {
    setMessages([]);
  };

  // Use the cleaner UI layout from the alternative version
  return (
    <div className="min-h-screen bg-gray-900 text-white flex flex-col items-center p-4">
      <div className="w-full max-w-2xl bg-gray-800 rounded-lg shadow-lg p-6">
        <h1 className="text-3xl font-bold mb-4 text-center">AI Chatbot by Simon Tingle</h1>
        
        {/* Enhanced message area with loading state */}
        <div className="h-96 overflow-y-auto mb-4 p-4 bg-gray-700 rounded-lg">
          {messages.map((msg, index) => (
            <div key={index} className={`mb-2 ${msg.role === 'user' ? 'text-right' : 'text-left'}`}>
              <span className={`inline-block p-2 rounded-lg ${
                msg.role === 'user' ? 'bg-blue-600' : 'bg-gray-600'
              }`}>
                {msg.content}
              </span>
            </div>
          ))}
          {loading && (
            <div className="text-left mb-2">
              <span className="inline-block p-2 rounded-lg bg-gray-600 text-gray-400">
                Thinking...
              </span>
            </div>
          )}
        </div>

        {/* Input area */}
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
            className="flex-1 p-2 rounded-lg bg-gray-600 text-white border-none focus:outline-none"
            placeholder="Type your message..."
            disabled={loading}
          />
          <button
            onClick={sendMessage}
            disabled={loading}
            className="px-4 py-2 bg-blue-500 rounded-lg hover:bg-blue-600 transition disabled:opacity-50"
          >
            {loading ? 'Sending...' : 'Send'}
          </button>
        </div>

        {/* Action buttons */}
        <div className="flex gap-2 mt-4">
          <button
            onClick={clearChat}
            className="flex-1 px-4 py-2 bg-yellow-500 rounded-lg hover:bg-yellow-600 transition"
          >
            Clear Chat
          </button>
          <button
            onClick={exportLogs}
            className="flex-1 px-4 py-2 bg-green-500 rounded-lg hover:bg-green-600 transition"
          >
            Export Logs
          </button>
        </div>

        {/* User ID display */}
        <div className="text-center text-sm text-gray-400 mt-4">
          User ID: {userId}
        </div>
      </div>
    </div>
  );
}

export default App;