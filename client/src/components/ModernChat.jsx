import React, { useState, useRef, useEffect } from 'react'
import DocumentManager from './DocumentManager'
import { useChat } from '../hooks/useChat'
import { chatService } from '../services/chatService'

// MUI Components
import {
  Button,
  Box,
  Paper,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  IconButton,
  Chip,
  Typography,
  CircularProgress,
  AppBar,
  Toolbar,
  Container
} from '@mui/material'

// MUI Icons
import {
  ShowChart,
  HealthAndSafety,
  Folder,
  Close,
  Send,
  Clear,
  CloudUpload
} from '@mui/icons-material'

const ModernChat = () => {
  const [input, setInput] = useState('')
  const [isDragging, setIsDragging] = useState(false)
  const [documentStatus, setDocumentStatus] = useState('')
  const [ragStats, setRagStats] = useState(null)
  const [showRagStats, setShowRagStats] = useState(false)
  const [showDocuments, setShowDocuments] = useState(false)
  const fileInputRef = useRef(null)
  const messagesEndRef = useRef(null)
  
  const { messages, isLoading, error, sendMessage, clearChat, addDocument } = useChat()

  // Auto-scroll to bottom of chat (KEEPING YOUR EXCELLENT SCROLL SYSTEM)
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isLoading])

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
      alert('Server: OK\nOllama: ' + (ollama.status === 'ok' ? 'Connected' : 'Disconnected'))
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
        console.log('📁 Processing file:', file.name, file.type)
        
        if (file.type.startsWith('text/') || file.name.endsWith('.txt') || file.name.endsWith('.md')) {
          const text = await file.text()
          console.log('📝 File content length:', text.length)
          
          const metadata = {
            fileName: file.name,
            fileSize: file.size,
            fileType: file.type,
            lastModified: new Date(file.lastModified).toISOString()
          }
          
          console.log('🚀 Calling addDocument with:', { text: text.substring(0, 50), metadata })
          await addDocument(text, metadata, 'default-user')
          console.log('✅ Successfully processed:', file.name)
          setDocumentStatus('✅ Processed: ' + file.name)
        } else {
          console.log('❌ Unsupported file type:', file.name, file.type)
          setDocumentStatus('❌ Unsupported file type: ' + file.name)
        }
      }
      
      setDocumentStatus('✅ All documents processed successfully (' + files.length + ' files)')
      setTimeout(() => setDocumentStatus(''), 3000)
    } catch (err) {
      console.error('❌ Error processing files:', err)
      setDocumentStatus('❌ Error: ' + err.message)
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
    <Container 
      maxWidth="lg" 
      sx={{ 
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        p: 2
      }}
    >
      <Box 
        sx={{
          display: 'flex',
          flexDirection: 'column',
          width: '100%',
          height: '90vh',
          bgcolor: 'grey.900',
          borderRadius: '16px',
          border: '1px solid',
          borderColor: 'grey.700',
          boxShadow: 8,
          overflow: 'hidden'
        }}
      >
        {/* Enhanced Header with MUI AppBar */}
        <AppBar 
          position="static" 
          sx={{ 
            bgcolor: 'grey.800',
            borderBottom: '1px solid',
            borderBottomColor: 'grey.700',
            borderRadius: '16px 16px 0 0'
          }}
        >
          <Toolbar sx={{ display: 'flex', justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <Box 
                sx={{ 
                  width: 12, 
                  height: 12, 
                  bgcolor: 'success.main',
                  borderRadius: '50%',
                  animation: 'pulse 2s infinite'
                }}
              />
              <Typography 
                variant="h6" 
                sx={{ 
                  fontWeight: 'bold',
                  background: 'linear-gradient(45deg, #2196F3, #9C27B0)',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                  backgroundClip: 'text'
                }}
              >
                AI Chat Assistant
              </Typography>
            </Box>
            
            <Box sx={{ display: 'flex', gap: 1 }}>
              <Button
                variant="outlined"
                startIcon={<Folder />}
                onClick={() => setShowDocuments(!showDocuments)}
                sx={{ 
                  borderRadius: '12px',
                  borderColor: 'grey.600',
                  color: 'grey.300',
                  '&:hover': {
                    borderColor: 'grey.500',
                    bgcolor: 'grey.700'
                  }
                }}
              >
                {showDocuments ? 'Hide Docs' : 'Show Docs'}
              </Button>
              
              <Button
                variant="contained"
                color="secondary"
                startIcon={<ShowChart />}
                onClick={handleRagStats}
                sx={{ borderRadius: '12px' }}
              >
                RAG Stats
              </Button>
              
              <Button
                variant="contained"
                color="primary"
                startIcon={<HealthAndSafety />}
                onClick={handleHealthCheck}
                sx={{ borderRadius: '12px' }}
              >
                Health
              </Button>
            </Box>
          </Toolbar>
        </AppBar>

        {/* Enhanced RAG Stats Modal with MUI Dialog */}
        <Dialog
          open={showRagStats}
          onClose={() => setShowRagStats(false)}
          maxWidth="sm"
          fullWidth
          PaperProps={{
            sx: {
              borderRadius: '16px',
              bgcolor: 'grey.800',
              border: '1px solid',
              borderColor: 'grey.700',
            }
          }}
        >
          <DialogTitle 
            sx={{ 
              display: 'flex', 
              justifyContent: 'space-between', 
              alignItems: 'center',
              bgcolor: 'grey.800',
              color: 'white'
            }}
          >
            RAG Statistics
            <IconButton 
              onClick={() => setShowRagStats(false)}
              sx={{ color: 'grey.400' }}
            >
              <Close />
            </IconButton>
          </DialogTitle>
          <DialogContent sx={{ bgcolor: 'grey.800' }}>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
              <Paper 
                sx={{ 
                  p: 2, 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center',
                  bgcolor: 'grey.700'
                }}
              >
                <Typography color="grey.300">Documents:</Typography>
                <Chip 
                  label={ragStats?.documentCount || 0} 
                  color="primary" 
                  sx={{ fontWeight: 'bold' }}
                />
              </Paper>
              
              <Paper 
                sx={{ 
                  p: 2, 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center',
                  bgcolor: 'grey.700'
                }}
              >
                <Typography color="grey.300">Vectors:</Typography>
                <Chip 
                  label={ragStats?.vectorCount || 0} 
                  color="secondary" 
                  sx={{ fontWeight: 'bold' }}
                />
              </Paper>
              
              <Paper 
                sx={{ 
                  p: 2, 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center',
                  bgcolor: 'grey.700'
                }}
              >
                <Typography color="grey.300">Dimensions:</Typography>
                <Chip 
                  label={ragStats?.dimensions || 0} 
                  color="success" 
                  sx={{ fontWeight: 'bold' }}
                />
              </Paper>
            </Box>
          </DialogContent>
        </Dialog>

        {/* Document Status */}
        {documentStatus && (
          <Box sx={{ 
            bgcolor: 'grey.800', 
            borderBottom: '1px solid',
            borderBottomColor: 'grey.700',
            p: 1,
            textAlign: 'center'
          }}>
            <Chip 
              label={documentStatus} 
              color={documentStatus.includes('✅') ? 'success' : documentStatus.includes('❌') ? 'error' : 'default'}
              sx={{ fontWeight: 'medium' }}
            />
          </Box>
        )}

        {/* Enhanced Drag & Drop Area */}
        <Box
          sx={{
            m: 2,
            borderRadius: '16px',
            border: '2px dashed',
            borderColor: isDragging ? 'primary.main' : 'grey.600',
            bgcolor: isDragging ? 'primary.900' : 'grey.800',
            p: 4,
            textAlign: 'center',
            cursor: 'pointer',
            transition: 'all 0.3s ease',
            '&:hover': {
              borderColor: 'grey.500',
              bgcolor: 'grey.700'
            }
          }}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
          onClick={() => fileInputRef.current?.click()}
        >
          <CloudUpload sx={{ fontSize: 48, color: 'grey.400', mb: 2 }} />
          <Typography variant="h6" color="grey.300">
            <span style={{ color: '#2196F3', fontWeight: 'bold' }}>Drag & drop</span> files here or click to browse
          </Typography>
          <Typography variant="body2" color="grey.500" sx={{ mt: 1 }}>
            Supports .txt and .md files
          </Typography>
          <input
            type="file"
            ref={fileInputRef}
            style={{ display: 'none' }}
            multiple
            accept=".txt,.md,text/*"
            onChange={handleFileSelect}
          />
        </Box>

        {/* Document Manager */}
        {showDocuments && (
          <Box sx={{ mx: 2, mb: 2 }}>
            <Paper 
              sx={{ 
                borderRadius: '16px', 
                border: '1px solid',
                borderColor: 'grey.600',
                bgcolor: 'grey.800'
              }}
            >
              <DocumentManager userId="default-user" />
            </Paper>
          </Box>
        )}

        {/* Enhanced Messages Container - PRESERVING YOUR EXCELLENT SCROLL SYSTEM */}
        <Box
          sx={{
            flex: 1,
            overflowY: 'auto',
            p: 2,
            bgcolor: 'grey.900',
            // Custom scrollbar styling
            '&::-webkit-scrollbar': {
              width: 8,
            },
            '&::-webkit-scrollbar-track': {
              bgcolor: 'grey.800',
            },
            '&::-webkit-scrollbar-thumb': {
              bgcolor: 'primary.main',
              borderRadius: 4,
            },
          }}
        >
          {messages.length === 0 ? (
            <Box 
              sx={{ 
                display: 'flex', 
                flexDirection: 'column', 
                alignItems: 'center', 
                justifyContent: 'center', 
                height: '100%',
                color: 'grey.500'
              }}
            >
              <Typography variant="h1" sx={{ mb: 2 }}>🤖</Typography>
              <Typography variant="h5">
                Start a conversation or drop documents to enhance knowledge
              </Typography>
            </Box>
          ) : (
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, maxWidth: 'lg', mx: 'auto' }}>
              {messages.map((message) => (
                <Paper
                  key={message.id}
                  elevation={3}
                  sx={{
                    p: 2,
                    borderRadius: '16px',
                    background: message.role === 'user' 
                      ? 'linear-gradient(135deg, #1e40af, #3b82f6)'
                      : message.role === 'assistant'
                      ? 'linear-gradient(135deg, #374151, #1f2937)'
                      : 'linear-gradient(135deg, #991b1b, #ef4444)',
                    maxWidth: message.role === 'user' ? '70%' : '100%',
                    ml: message.role === 'user' ? 'auto' : 0,
                    border: '1px solid',
                    borderColor: message.role === 'user' 
                      ? 'blue.600' 
                      : message.role === 'assistant' 
                      ? 'grey.600' 
                      : 'red.600',
                  }}
                >
                  <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
                    <Box
                      sx={{
                        width: 40,
                        height: 40,
                        borderRadius: '50%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: 'bold',
                        bgcolor: message.role === 'user' 
                          ? 'blue.600' 
                          : message.role === 'assistant' 
                          ? 'purple.600' 
                          : 'red.600',
                        fontSize: '1rem'
                      }}
                    >
                      {message.role === 'user' ? '👤' : message.role === 'assistant' ? '🤖' : '⚠️'}
                    </Box>
                    <Box sx={{ flex: 1 }}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1 }}>
                        <Typography 
                          variant="subtitle1" 
                          sx={{ 
                            fontWeight: 'bold',
                            color: 'white',
                            textTransform: 'capitalize'
                          }}
                        >
                          {message.role === 'user' ? 'You' : message.role === 'assistant' ? 'Assistant' : 'Error'}
                        </Typography>
                        {message.responseTime && (
                          <Chip 
                            label={message.responseTime} 
                            size="small" 
                            sx={{ 
                              bgcolor: 'grey.700', 
                              color: 'grey.300',
                              height: '20px'
                            }}
                          />
                        )}
                      </Box>
                      <Typography 
                        sx={{ 
                          color: 'grey.100', 
                          lineHeight: 1.6,
                          mb: 1
                        }}
                      >
                        {formatMessageContent(message.content)}
                      </Typography>
                      <Typography 
                        variant="caption" 
                        sx={{ 
                          color: 'grey.400' 
                        }}
                      >
                        {new Date(message.timestamp).toLocaleTimeString()}
                      </Typography>
                    </Box>
                  </Box>
                </Paper>
              ))}
              {isLoading && (
                <Paper
                  sx={{
                    p: 2,
                    borderRadius: '16px',
                    background: 'linear-gradient(135deg, #374151, #1f2937)',
                    maxWidth: '100%',
                    border: '1px solid',
                    borderColor: 'grey.600',
                  }}
                >
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Box
                      sx={{
                        width: 40,
                        height: 40,
                        borderRadius: '50%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        bgcolor: 'purple.600',
                        fontSize: '1rem'
                      }}
                    >
                      🤖
                    </Box>
                    <Box sx={{ display: 'flex', gap: 1 }}>
                      <CircularProgress size={16} sx={{ color: 'grey.400' }} />
                      <CircularProgress size={16} sx={{ color: 'grey.400', animationDelay: '0.1s' }} />
                      <CircularProgress size={16} sx={{ color: 'grey.400', animationDelay: '0.2s' }} />
                    </Box>
                  </Box>
                </Paper>
              )}
              <div ref={messagesEndRef} />
            </Box>
          )}
        </Box>

        {/* Error */}
        {error && (
          <Box sx={{ mx: 2, mb: 2 }}>
            <Paper 
              sx={{ 
                p: 2, 
                bgcolor: 'error.900', 
                border: '1px solid',
                borderColor: 'error.700',
                borderRadius: '16px'
              }}
            >
              <Typography variant="body2" sx={{ color: 'error.200' }}>
                ⚠️ {error}
              </Typography>
            </Paper>
          </Box>
        )}

        {/* Enhanced Input with MUI TextField */}
        <Box 
          component="form" 
          onSubmit={handleSubmit}
          sx={{ 
            p: 2, 
            borderTop: '1px solid',
            borderTopColor: 'grey.800',
            bgcolor: 'grey.800'
          }}
        >
          <Box sx={{ display: 'flex', gap: 2, maxWidth: 'lg', mx: 'auto' }}>
            <TextField
              fullWidth
              variant="outlined"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Message AI assistant..."
              disabled={isLoading}
              sx={{
                '& .MuiOutlinedInput-root': {
                  bgcolor: 'grey.700',
                  borderRadius: '16px',
                  '& fieldset': {
                    borderColor: 'grey.600',
                  },
                  '&:hover fieldset': {
                    borderColor: 'grey.500',
                  },
                  '&.Mui-focused fieldset': {
                    borderColor: 'primary.main',
                  },
                },
                '& .MuiInputBase-input': {
                  color: 'white',
                  fontSize: '1rem',
                },
                '& .MuiInputBase-input::placeholder': {
                  color: 'grey.400',
                },
              }}
            />
            
            <Button
              type="submit"
              disabled={!input.trim() || isLoading}
              variant="contained"
              startIcon={isLoading ? <CircularProgress size={20} /> : <Send />}
              sx={{
                borderRadius: '16px',
                background: 'linear-gradient(45deg, #2196F3, #9C27B0)',
                '&:hover': {
                  background: 'linear-gradient(45deg, #1976D2, #7B1FA2)',
                },
                minWidth: '120px',
                height: '56px'
              }}
            >
              {isLoading ? 'Sending...' : 'Send'}
            </Button>
            
            <Button
              type="button"
              onClick={clearChat}
              variant="outlined"
              startIcon={<Clear />}
              sx={{
                borderRadius: '16px',
                borderColor: 'grey.600',
                color: 'grey.300',
                '&:hover': {
                  borderColor: 'grey.500',
                  bgcolor: 'grey.700',
                },
                minWidth: '100px',
                height: '56px'
              }}
            >
              Clear
            </Button>
          </Box>
        </Box>
      </Box>
    </Container>
  )
}

export default ModernChat