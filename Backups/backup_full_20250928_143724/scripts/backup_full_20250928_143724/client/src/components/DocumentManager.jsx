import React, { useState, useEffect } from 'react'
import { chatService } from '../services/chatService'

const DocumentManager = ({ userId = 'default-user' }) => {
  const [documents, setDocuments] = useState([])
  const [loading, setLoading] = useState(false)
  const [deleting, setDeleting] = useState(null)

  const loadDocuments = async () => {
    try {
      setLoading(true)
      const docs = await chatService.listDocuments(userId)
      setDocuments(docs)
    } catch (error) {
      console.error('Failed to load documents:', error)
    } finally {
      setLoading(false)
    }
  }

  const deleteDocument = async (fileName) => {
    if (!window.confirm(`Are you sure you want to delete "${fileName}"?`)) {
      return
    }

    try {
      setDeleting(fileName)
      await chatService.deleteDocument(fileName, userId)
      await loadDocuments() // Refresh the list
    } catch (error) {
      console.error('Failed to delete document:', error)
      alert('Failed to delete document: ' + error.message)
    } finally {
      setDeleting(null)
    }
  }

  useEffect(() => {
    loadDocuments()
  }, [])

  if (loading) {
    return (
      <div className="p-4 text-center text-gray-400">
        Loading documents...
      </div>
    )
  }

  return (
    <div className="p-4">
      <h3 className="text-lg font-bold mb-4 text-gray-200">Uploaded Documents ({documents.length})</h3>
      
      {documents.length === 0 ? (
        <div className="text-gray-500 text-center py-8">
          No documents uploaded yet
        </div>
      ) : (
        <div className="space-y-3 max-h-60 overflow-y-auto">
          {documents.map((doc) => (
            <div key={doc.id} className="flex items-center justify-between p-3 bg-gray-700/50 rounded-lg">
              <div className="flex-1 min-w-0">
                <div className="font-medium text-gray-200 truncate">{doc.fileName}</div>
                <div className="text-xs text-gray-400">
                  {new Date(doc.createdAt).toLocaleDateString()} • 
                  {doc.fileSize ? (doc.fileSize / 1024).toFixed(1) : '0'} KB
                </div>
              </div>
              <button
                onClick={() => deleteDocument(doc.fileName)}
                disabled={deleting === doc.fileName}
                className="ml-3 px-3 py-1 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm disabled:opacity-50"
              >
                {deleting === doc.fileName ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default DocumentManager
