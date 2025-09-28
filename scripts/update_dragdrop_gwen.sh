#!/bin/bash

echo "🚀 Starting drag & drop and document management update..."

# Update backend/server.js with new endpoints
echo "🔧 Updating backend server.js..."

# Create backup of server.js first
cp backend/server.js backend/server.js.pre_dragdrop_backup

# Add document list endpoint to server.js
if ! grep -q "app.get('/api/documents'" backend/server.js; then
    # Find a good place to insert the endpoints (before the final error handler)
    sed -i '' '/app.use((req, res) => {/i\
\
// LIST DOCUMENTS ENDPOINT\
app.get('"'"'/api/documents'"'"', authenticateUser, async (req, res) => {\
  try {\
    const userId = req.user?.id || '"'"'default'"'"';\
    \
    if (!vectorStore) {\
      return safeJson(res, 503, { error: '"'"'Vector store not initialized'"'"' });\
    }\
    \
    const userDocuments = vectorStore.documents\
      .filter(doc => (doc.metadata.userId || '"'"'default'"'"') === userId)\
      .map(doc => ({\
        fileName: doc.metadata.fileName,\
        fileSize: doc.metadata.fileSize,\
        fileType: doc.metadata.fileType,\
        createdAt: doc.createdAt,\
        id: doc.id\
      }));\
    \
    safeJson(res, 200, { documents: userDocuments });\
  } catch (error) {\
    console.error('"'"'🚨 Document list error:'"'", error);\
    safeJson(res, 500, { \
      success: false, \
      error: '"'"'Failed to list documents'"'"' \
    });\
  }\
});\
\
// DELETE DOCUMENT ENDPOINT\
app.delete('"'"'/api/documents/:fileName'"'"', authenticateUser, async (req, res) => {\
  try {\
    const { fileName } = req.params;\
    const userId = req.user?.id || '"'"'default'"'"';\
    \
    if (!vectorStore) {\
      return safeJson(res, 503, { error: '"'"'Vector store not initialized'"'"' });\
    }\
    \
    // Find and remove document\
    const initialLength = vectorStore.documents.length;\
    vectorStore.documents = vectorStore.documents.filter(doc => \
      !((doc.metadata.fileName === fileName || doc.metadata.originalName === fileName) && (doc.metadata.userId || '"'"'default'"'"') === userId)\
    );\
    vectorStore.vectors = vectorStore.vectors.slice(0, vectorStore.documents.length);\
    \
    const deletedCount = initialLength - vectorStore.documents.length;\
    \
    if (deletedCount > 0) {\
      // Save updated vector store\
      await saveVectorStore();\
      \
      // Log the deletion\
      try {\
        const fs = require('"'"'fs'"'"');\
        const path = require('"'"'path'"'"');\
        const LOG_DIR = path.join(__dirname, '"'"'logs'"'"');\
        fs.appendFileSync(\
          path.join(LOG_DIR, '"'"'documents.log'"'"'),\
          `[${new Date().toISOString()}] User ${userId} deleted: ${fileName}\
`\
        );\
      } catch (error) {\
        console.error('"'"'❌ Failed to log document deletion:'"'", error.message);\
      }\
      \
      safeJson(res, 200, { \
        success: true, \
        message: `Deleted ${deletedCount} document(s)`,\
        deletedCount \
      });\
    } else {\
      safeJson(res, 404, { \
        success: false, \
        message: '"'"'Document not found'"'"' \
      });\
    }\
  } catch (error) {\
    console.error('"'"'🚨 Document deletion error:'"'", error);\
    safeJson(res, 500, { \
      success: false, \
      error: '"'"'Failed to delete document'"'"' \
    });\
  }\
});\
\
' backend/server.js

    echo "✅ Added document list and delete endpoints to server.js"
else
    echo "⚠️  Document endpoints already exist in server.js"
fi

# Update backend/rag.js to ensure userId tracking
echo "🔧 Updating backend rag.js..."
cp backend/rag.js backend/rag.js.pre_update_backup

# Update addDocument function in rag.js
sed -i '' '/async function addDocument(/,/^}/c\
async function addDocument(text, metadata, storeRef) {\
  try {\
    console.log(`📄 Adding document text length: ${text.length} chars`);\
    \
    const targetStore = storeRef || vectorStore;\
    const vector = textToVector(text);\
    const document = {\
      id: Date.now().toString() + Math.random().toString(36).substr(2, 5),\
      text: text,\
      metadata: {\
        ...metadata,\
        userId: metadata.userId || metadata.userId || '"'"'default'"'"',\
        uploadedAt: new Date().toISOString()\
      },\
      createdAt: new Date().toISOString(),\
      vector: vector\
    };\
    \
    targetStore.documents.push(document);\
    targetStore.vectors.push(vector);\
    \
    // Save to persistent storage\
    const success = await saveVectorStore();\
    \
    if (success) {\
      console.log(`✅ Document added successfully. Total documents: ${targetStore.documents.length}`);\
    } else {\
      console.log(`⚠️  Document added to memory but save failed`);\
    }\
    \
    return true;\
  } catch (error) {\
    console.error('"'"'❌ Error adding document:'"'", error);\
    return false;\
  }\
}' backend/rag.js

echo "✅ Updated rag.js with userId tracking"

# Update frontend services
echo "🔧 Updating frontend chatService.js..."

# Create backup first
cp client/src/services/chatService.js client/src/services/chatService.js.pre_update_backup

# Add new methods to chatService.js
if ! grep -q "listDocuments" client/src/services/chatService.js; then
    # Find the position to insert new methods (before the closing brace)
    sed -i '' '/healthCheck: async/i\
\
  // NEW: List all documents\
  listDocuments: async (userId = '"'"'default-user'"'"') => {\
    try {\
      const response = await api.get('"'"'/api/documents'"'"', { params: { userId } });\
      return response.data.documents || [];\
    } catch (error) {\
      throw new Error(error.response?.data?.error || '"'"'Failed to list documents'"'"');\
    }\
  },\
\
  // NEW: Delete a document\
  deleteDocument: async (fileName, userId = '"'"'default-user'"'"') => {\
    try {\
      const response = await api.delete(`/api/documents/${fileName}`, { data: { userId } });\
      return response.data;\
    } catch (error) {\
      throw new Error(error.response?.data?.error || '"'"'Failed to delete document'"'"');\
    }\
  },\
\
' client/src/services/chatService.js

    echo "✅ Added listDocuments and deleteDocument methods to chatService.js"
else
    echo "⚠️  Document management methods already exist in chatService.js"
fi

# Create DocumentManager component
echo "🔧 Creating DocumentManager component..."
mkdir -p client/src/components

cat > client/src/components/DocumentManager.jsx << 'EOFF'
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
EOFF

echo "✅ Created DocumentManager.jsx"

# Update ModernChat.jsx with document management
echo "🔧 Updating ModernChat.jsx with document management..."

# Create backup first
cp client/src/components/ModernChat.jsx client/src/components/ModernChat.jsx.pre_update_backup

# Add import for DocumentManager
if ! grep -q "DocumentManager" client/src/components/ModernChat.jsx; then
    sed -i '' '/import.*useChat/i\
import DocumentManager from '\''./DocumentManager'\''\
' client/src/components/ModernChat.jsx
    echo "✅ Added DocumentManager import"
fi

# Add state for showing documents
if ! grep -q "showDocuments" client/src/components/ModernChat.jsx; then
    sed -i '' '/const \[showRagStats, setShowRagStats\]/a\
  const \[showDocuments, setShowDocuments\] = useState(false)\
' client/src/components/ModernChat.jsx
    echo "✅ Added showDocuments state"
fi

# Add document management button to header
if ! grep -q "Show Docs" client/src/components/ModernChat.jsx; then
    sed -i '' '/<button.*RAG Stats/,/<\/div>/s/<\/div>/  <button \
  onClick={() => setShowDocuments(!showDocuments)}\
  className="bg-gray-700 hover:bg-gray-600 px-4 py-2 rounded-xl text-sm transition-all duration-200 shadow-md hover:shadow-lg font-medium"\
>\
  {showDocuments ? '\''Hide Docs'\'' : '\''Show Docs'\''}\
<\/button>\
<\/div>/' client/src/components/ModernChat.jsx
    echo "✅ Added document management button"
fi

# Add document manager section
if ! grep -q "DocumentManager.*userId" client/src/components/ModernChat.jsx; then
    # Find a good place to insert (after drag & drop area)
    sed -i '' '/<input/a\
      />\
    </div>\
  </div>\
\
  {/* Document Manager */}\
  {showDocuments && (\
    <div className="mx-6 mb-4 rounded-2xl border border-gray-600 bg-gray-800/50">\
      <DocumentManager userId="default-user" />\
    </div>\
  )}\
\
  {/* Messages */}\
  <div' client/src/components/ModernChat.jsx
    echo "✅ Added document manager section"
fi

echo "✅ Updated ModernChat.jsx with document management"

# Add comprehensive drag & drop debugging
echo "🔧 Adding drag & drop debugging..."

# Update processFiles function with comprehensive debugging
sed -i '' '/const processFiles = async (files) =>/,/setTimeout(() => setDocumentStatus(''''), 5000)/c\
  const processFiles = async (files) => {\
    console.log('\''🔄 Starting file processing for'\'', files.length, '\''files'\'');\
    setDocumentStatus('\''Processing documents...'\'');\
    \
    try {\
      let processedCount = 0;\
      \
      for (const file of files) {\
        console.log('\''📄 Processing:'\'', file.name, '\''Type:'\'', file.type, '\''Size:'\'', file.size);\
        \
        if (file.type.startsWith('\''text/'\'') || file.name.endsWith('\''\.txt'\'') || file.name.endsWith('\''\.md'\'')) {\
          console.log('\''✅ File type accepted'\'');\
          \
          try {\
            const text = await file.text();\
            console.log('\''📝 Text extracted, length:'\'', text.length);\
            \
            const metadata = {\
              fileName: file.name,\
              fileSize: file.size,\
              fileType: file.type,\
              lastModified: new Date(file.lastModified).toISOString(),\
              userId: '\''default-user'\''\
            };\
            \
            console.log('\''🚀 Calling addDocument with metadata:'\'', metadata);\
            await addDocument(text, metadata, '\''default-user'\'');\
            console.log('\''✅ Successfully processed:'\'', file.name);\
            \
            processedCount++;\
            setDocumentStatus(`✅ Processed: ${file.name}`);\
          } catch (fileError) {\
            console.error('\''❌ Error processing file'\'', file.name, '\'':'\'', fileError);\
            setDocumentStatus(`❌ Error processing ${file.name}: ${fileError.message}`);\
            throw fileError;\
          }\
        } else {\
          console.log('\''❌ Unsupported file type:'\'', file.name);\
          setDocumentStatus(`❌ Unsupported file type: ${file.name}`);\
        }\
      }\
      \
      setDocumentStatus(`✅ Successfully processed ${processedCount} of ${files.length} files`);\
      console.log('\''🎉 File processing completed:'\'', processedCount, '\''files processed'\'');\
      \
      setTimeout(() => setDocumentStatus(''''), 3000);\
    } catch (err) {\
      console.error('\''💥 Error in processFiles:'\'', err);\
      setDocumentStatus(`❌ Processing failed: ${err.message}`);\
      setTimeout(() => setDocumentStatus(''''), 5000);\
    }\
  }' client/src/components/ModernChat.jsx

echo "✅ Added comprehensive drag & drop debugging"

# Update useChat.js with debugging
echo "🔧 Updating useChat.js with debugging..."

# Create backup first
cp client/src/hooks/useChat.js client/src/hooks/useChat.js.pre_update_backup

# Update addDocument function with debugging
sed -i '' '/const addDocument = useCallback(async (text, metadata = {}, userId = '\''default-user'\'') =>/,/return response;/c\
  const addDocument = useCallback(async (text, metadata = {}, userId = '\''default-user'\'') => {\
    try {\
      setIsLoading(true);\
      setError(null);\
      console.log('\''📤 Uploading document to backend...'\'' , { text: text.substring(0, 50), metadata, userId });\
      const response = await chatService.uploadDocument(text, metadata, userId);\
      console.log('\''📥 Document upload response:'\'', response);\
      return response;\
    } catch (err) {\
      console.error('\''💥 Document upload error:'\'', err);\
      setError(err.message);\
      throw err;\
    } finally {\
      setIsLoading(false);\
    }\
  }, [])' client/src/hooks/useChat.js

echo "✅ Updated useChat.js with debugging"

echo "🎉 Update completed successfully!"
echo ""
echo "📋 NEXT STEPS:"
echo "1. Restart your backend server: cd backend && node server.js"
echo "2. Restart your frontend: cd client && npm run dev"
echo "3. Open browser to http://localhost:5173"
echo "4. Test drag & drop - check browser console for detailed logs"
echo "5. Use 'Show Docs' button to manage documents"

