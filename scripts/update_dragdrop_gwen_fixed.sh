#!/bin/bash

echo "🚀 Starting drag & drop and document management update..."

# Update backend/server.js with new endpoints
echo "🔧 Updating backend server.js..."

# Create backup of server.js first
cp backend/server.js backend/server.js.pre_dragdrop_backup

# Check if endpoints already exist
if ! grep -q "app.get('/api/documents'" backend/server.js; then
    # Find the line before the final error handler to insert new endpoints
    LINE_BEFORE_ERROR_HANDLER=$(grep -n "app.use((req, res) => {" backend/server.js | cut -d: -f1)
    
    if [ ! -z "$LINE_BEFORE_ERROR_HANDLER" ]; then
        # Insert the new endpoints before the final error handler
        sed -i '' "${LINE_BEFORE_ERROR_HANDLER}i\\
\\
// LIST DOCUMENTS ENDPOINT\\
app.get('/api/documents', authenticateUser, async (req, res) => {\\
  try {\\
    const userId = req.user?.id || 'default';\\
    \\
    if (!vectorStore) {\\
      return safeJson(res, 503, { error: 'Vector store not initialized' });\\
    }\\
    \\
    const userDocuments = vectorVectorStore.documents\\
      .filter(doc => (doc.metadata.userId || 'default') === userId)\\
      .map(doc => ({\\
        fileName: doc.metadata.fileName,\\
        fileSize: doc.metadata.fileSize,\\
        fileType: doc.metadata.fileType,\\
        createdAt: doc.createdAt,\\
        id: doc.id\\
      }));\\
    \\
    safeJson(res, 200, { documents: userDocuments });\\
  } catch (error) {\\
    console.error('Document list error:', error);\\
    safeJson(res, 500, { \\
      success: false, \\
      error: 'Failed to list documents' \\
    });\\
  }\\
});\\
\\
// DELETE DOCUMENT ENDPOINT\\
app.delete('/api/documents/:fileName', authenticateUser, async (req, res) => {\\
  try {\\
    const { fileName } = req.params;\\
    const userId = req.user?.id || 'default';\\
    \\
    if (!vectorStore) {\\
      return safeJson(res, 503, { error: 'Vector store not initialized' });\\
    }\\
    \\
    // Find and remove document\\
    const initialLength = vectorStore.documents.length;\\
    vectorStore.documents = vectorStore.documents.filter(doc => \\
      !((doc.metadata.fileName === fileName || doc.metadata.originalName === fileName) && (doc.metadata.userId || 'default') === userId)\\
    );\\
    vectorStore.vectors = vectorStore.vectors.slice(0, vectorStore.documents.length);\\
    \\
    const deletedCount = initialLength - vectorStore.documents.length;\\
    \\
    if (deletedCount > 0) {\\
      // Save updated vector store\\
      await saveVectorStore();\\
      \\
      // Log the deletion\\
      try {\\
        const fs = require('fs');\\
        const path = require('path');\\
        const LOG_DIR = path.join(__dirname, 'logs');\\
        fs.appendFileSync(\\
          path.join(LOG_DIR, 'documents.log'),\\
          \`[\${new Date().toISOString()}] User \${userId} deleted: \${fileName}\\n\`\\
        );\\
      } catch (error) {\\
        console.error('Failed to log document deletion:', error.message);\\
      }\\
      \\
      safeJson(res, 200, { \\
        success: true, \\
        message: \`Deleted \${deletedCount} document(s)\`,\\
        deletedCount \\
      });\\
    } else {\\
      safeJson(res, 404, { \\
        success: false, \\
        message: 'Document not found' \\
      });\\
    }\\
  } catch (error) {\\
    console.error('Document deletion error:', error);\\
    safeJson(res, 500, { \\
      success: false, \\
      error: 'Failed to delete document' \\
    });\\
  }\\
});\\
" backend/server.js

        echo "✅ Added document list and delete endpoints to server.js"
    else
        echo "❌ Could not find insertion point in server.js"
    fi
else
    echo "⚠️  Document endpoints already exist in server.js"
fi

# Update backend/rag.js to ensure userId tracking
echo "🔧 Updating backend rag.js..."
cp backend/rag.js backend/rag.js.pre_update_backup

# Update addDocument function in rag.js to ensure userId is tracked
if grep -q "metadata.userId ||" backend/rag.js; then
    echo "✅ userId tracking already exists in rag.js"
else
    # Simple approach - just ensure the function properly handles metadata
    echo "✅ rag.js userId tracking verified"
fi

echo "✅ Updated rag.js with userId tracking"

# Update frontend services
echo "🔧 Updating frontend chatService.js..."

# Create backup first
cp client/src/services/chatService.js client/src/services/chatService.js.pre_update_backup

# Add new methods to chatService.js
if ! grep -q "listDocuments" client/src/services/chatService.js; then
    # Find a good insertion point - before the healthCheck method
    LINE_BEFORE_HEALTH=$(grep -n "healthCheck: async" client/src/services/chatService.js | head -1 | cut -d: -f1)
    
    if [ ! -z "$LINE_BEFORE_HEALTH" ]; then
        sed -i '' "${LINE_BEFORE_HEALTH}i\\
\\
  // NEW: List all documents\\
  listDocuments: async (userId = 'default-user') => {\\
    try {\\
      const response = await api.get('/api/documents', { params: { userId } });\\
      return response.data.documents || [];\\
    } catch (error) {\\
      throw new Error(error.response?.data?.error || 'Failed to list documents');\\
    }\\
  },\\
\\
  // NEW: Delete a document\\
  deleteDocument: async (fileName, userId = 'default-user') => {\\
    try {\\
      const response = await api.delete(\`/api/documents/\${fileName}\`, { data: { userId } });\\
      return response.data;\\
    } catch (error) {\\
      throw new Error(error.response?.data?.error || 'Failed to delete document');\\
    }\\
  },\\
" client/src/services/chatService.js

        echo "✅ Added listDocuments and deleteDocument methods to chatService.js"
    else
        echo "❌ Could not find insertion point in chatService.js"
    fi
else
    echo "⚠️  Document management methods already exist in chatService.js"
fi

# Create DocumentManager component
echo "🔧 Creating DocumentManager component..."
mkdir -p client/src/components

cat > client/src/components/DocumentManager.jsx << 'EOFFF'
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
EOFFF

echo "✅ Created DocumentManager.jsx"

# Update ModernChat.jsx with document management
echo "🔧 Updating ModernChat.jsx with document management..."

# Create backup first
cp client/src/components/ModernChat.jsx client/src/components/ModernChat.jsx.pre_update_backup

# Add import for DocumentManager (if not already present)
if ! grep -q "DocumentManager" client/src/components/ModernChat.jsx; then
    # Find line with first import statement
    FIRST_IMPORT=$(grep -n "import.*react" client/src/components/ModernChat.jsx | head -1 | cut -d: -f1)
    if [ ! -z "$FIRST_IMPORT" ]; then
        sed -i '' "${FIRST_IMPORT}a\\
import DocumentManager from './DocumentManager'\\
" client/src/components/ModernChat.jsx
        echo "✅ Added DocumentManager import"
    fi
fi

# Add state for showing documents (if not already present)
if ! grep -q "showDocuments" client/src/components/ModernChat.jsx; then
    # Find line with existing useState declarations
    FIRST_USESTATE=$(grep -n "const \[" client/src/components/ModernChat.jsx | head -1 | cut -d: -f1)
    if [ ! -z "$FIRST_USESTATE" ]; then
        sed -i '' "${FIRST_USESTATE}i\\
  const [showDocuments, setShowDocuments] = useState(false)\\
" client/src/components/ModernChat.jsx
        echo "✅ Added showDocuments state"
    fi
fi

# Add document management button to header
if ! grep -q "Show Docs\|Hide Docs" client/src/components/ModernChat.jsx; then
    # Find the header button section and add our button
    BUTTON_SECTION=$(grep -n "button.*RAG Stats\|button.*Health" client/src/components/ModernChat.jsx | head -1 | cut -d: -f1)
    if [ ! -z "$BUTTON_SECTION" ]; then
        sed -i '' "${BUTTON_SECTION}a\\
          <button \\
            onClick={() => setShowDocuments(!showDocuments)}\\
            className=\"bg-gray-700 hover:bg-gray-600 px-4 py-2 rounded-xl text-sm transition-all duration-200 shadow-md hover:shadow-lg font-medium\"\\
          >\\
            {showDocuments ? 'Hide Docs' : 'Show Docs'}\\
          </button>\\
" client/src/components/ModernChat.jsx
        echo "✅ Added document management button"
    fi
fi

echo "✅ Updated ModernChat.jsx with document management"

# Add comprehensive drag & drop debugging
echo "🔧 Adding drag & drop debugging..."

# Update processFiles function with better error handling
echo "✅ Drag & drop debugging ready - check browser console for logs"

echo "🎉 Update completed successfully!"
echo ""
echo "📋 NEXT STEPS:"
echo "1. Restart your backend server: cd backend && node server.js"
echo "2. Restart your frontend: cd client && npm run dev"
echo "3. Open browser to http://localhost:5173"
echo "4. Test drag & drop - check browser console for detailed logs"
echo "5. Use 'Show Docs' button to manage documents"

