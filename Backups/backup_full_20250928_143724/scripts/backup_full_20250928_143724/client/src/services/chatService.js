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


  // NEW: List all documents
  listDocuments: async (userId = 'default-user') => {
    try {
      const response = await api.get('/api/documents', { params: { userId } });
      return response.data.documents || [];
    } catch (error) {
      throw new Error(error.response?.data?.error || 'Failed to list documents');
    }
  },

  // NEW: Delete a document
  deleteDocument: async (fileName, userId = 'default-user') => {
    try {
      const response = await api.delete(`/api/documents/${fileName}`, { data: { userId } });
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.error || 'Failed to delete document');
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
