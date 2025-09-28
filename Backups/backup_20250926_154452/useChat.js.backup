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
      console.log('📤 Uploading document to backend...', { text: text.substring(0, 50), metadata, userId })
      const response = await chatService.uploadDocument(text, metadata, userId)
      console.log('📥 Document upload response:', response)
      return response
    } catch (err) {
      console.error('💥 Document upload error:', err)
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
