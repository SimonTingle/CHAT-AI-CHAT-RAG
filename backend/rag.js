// backend/rag.js
const lancedb = require('@lancedb/lancedb');
const fetch = require('node-fetch');
const path = require('path');
const fs = require('fs');

// Configuration - Using proper embedding models with environment variables
const EMBEDDING_DIMENSION = parseInt(process.env.EMBEDDING_DIMENSION) || 768;
const OLLAMA_EMBEDDING_MODEL = process.env.OLLAMA_EMBEDDING_MODEL || 'nomic-embed-text';
const OLLAMA_BASE_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const RAG_MAX_RESULTS = parseInt(process.env.RAG_MAX_RESULTS) || 3;
const RAG_RELEVANCE_THRESHOLD = parseFloat(process.env.RAG_RELEVANCE_THRESHOLD) || 0.1;

// Vector store configuration
const VECTOR_STORE_PATH = path.join(__dirname, 'vectorstore', 'data');
const TABLE_NAME = 'documents';

// Ensure vector store directory exists
if (!fs.existsSync(VECTOR_STORE_PATH)) {
  fs.mkdirSync(VECTOR_STORE_PATH, { recursive: true });
}

/**
 * Generate embeddings using Ollama's embedding API
 * @param {string} text - Text to generate embedding for
 * @returns {Promise<number[]>} Embedding vector
 */
async function generateEmbedding(text) {
  if (!text || typeof text !== 'string') {
    console.warn('⚠️ Invalid text for embedding:', text);
    return Array(EMBEDDING_DIMENSION).fill(0);
  }

  try {
    const response = await fetch(`${OLLAMA_BASE_URL}/api/embeddings`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        model: OLLAMA_EMBEDDING_MODEL,
        prompt: text.trim()
      }),
      timeout: 30000
    });
    
    if (!response.ok) {
      throw new Error(`Ollama embedding failed: ${response.status} ${response.statusText}`);
    }
    
    const data = await response.json();
    
    if (!data.embedding || !Array.isArray(data.embedding)) {
      throw new Error('Invalid embedding response format');
    }
    
    // Validate embedding dimension
    if (data.embedding.length !== EMBEDDING_DIMENSION) {
      console.warn(`⚠️ Embedding dimension mismatch: expected ${EMBEDDING_DIMENSION}, got ${data.embedding.length}. Using as-is.`);
    }
    
    console.log(`✅ Generated embedding for text (${text.length} chars)`);
    return data.embedding;
    
  } catch (error) {
    console.error('❌ Embedding generation error:', error.message);
    
    // Fallback: return random embedding (better than zeros for similarity search)
    return Array(EMBEDDING_DIMENSION).fill(0).map(() => Math.random() * 2 - 1);
  }
}

/**
 * Initialize the vector store
 * @returns {Promise<Object>} LanceDB table instance
 */
async function initVectorStore() {
  try {
    console.log(`📊 Initializing vector store at: ${VECTOR_STORE_PATH}`);
    
    const db = await lancedb.connect(VECTOR_STORE_PATH);
    let table;
    
    try {
      table = await db.openTable(TABLE_NAME);
      console.log(`✅ Table '${TABLE_NAME}' loaded successfully`);
      
    } catch (error) {
      // Fix: Check for both error message variations
      if (error.message.includes('Table does not exist') || error.message.includes('was not found')) {
        console.log(`🆕 Table '${TABLE_NAME}' not found. Creating new table...`);
        
        const sampleText = "Welcome to the AI chatbot. This system uses RAG to provide contextual responses.";
        const sampleEmbedding = await generateEmbedding(sampleText);
        
        table = await db.createTable(TABLE_NAME, [
          { 
            id: 'sample-1', 
            text: sampleText,
            vector: sampleEmbedding,
            source: 'system',
            timestamp: new Date().toISOString()
          }
        ]);
        
        console.log(`✅ Table '${TABLE_NAME}' created with sample document`);
      } else {
        throw error;
      }
    }
    
    return table;
    
  } catch (error) {
    console.error('❌ Failed to initialize vector store:', error);
    throw error; // Don't wrap the error to see the original message
  }
}

/**
 * Add document to vector store
 * @param {string} text - Document text
 * @param {Object} metadata - Additional metadata
 * @param {Object} table - LanceDB table instance
 * @returns {Promise<boolean>} Success status
 */
async function addDocument(text, metadata = {}, table) {
  try {
    if (!table) {
      throw new Error('Vector store table not initialized');
    }
    
    const embedding = await generateEmbedding(text);
    const documentId = `doc-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
    
    const document = {
      id: documentId,
      text: text.substring(0, 10000), // Limit text length
      vector: embedding,
      source: metadata.source || 'user',
      timestamp: new Date().toISOString(),
      metadata: {
        ...metadata,
        length: text.length,
        chunks: Math.ceil(text.length / 1000)
      }
    };
    
    await table.add([document]);
    console.log(`✅ Document added to vector store: ${documentId}`);
    return true;
    
  } catch (error) {
    console.error('❌ Failed to add document:', error);
    return false;
  }
}

/**
 * Query vector store for similar documents
 * @param {string} query - Search query
 * @param {Object} table - LanceDB table instance
 * @param {number} limit - Number of results to return
 * @returns {Promise<string>} Combined context from similar documents
 */
async function queryVectorStore(query, table, limit = RAG_MAX_RESULTS) {
  try {
    if (!table) {
      console.warn('⚠️ Vector store not initialized');
      return '';
    }
    
    if (!query || typeof query !== 'string') {
      console.warn('⚠️ Invalid query for vector search');
      return '';
    }
    
    console.log(`🔍 Querying vector store: "${query.substring(0, 50)}..." (limit: ${limit})`);
    
    const queryEmbedding = await generateEmbedding(query);
    const results = await table
      .search(queryEmbedding)
      .limit(limit)
      .execute();
    
    if (results.length === 0) {
      console.log('📭 No relevant documents found');
      return '';
    }
    
    // Combine results, filtering out low-quality matches using the threshold
    const relevantResults = results.filter(result => {
      const score = result._distance || result.score;
      return score > RAG_RELEVANCE_THRESHOLD;
    });
    
    if (relevantResults.length === 0) {
      console.log(`📭 No documents above relevance threshold (${RAG_RELEVANCE_THRESHOLD})`);
      return '';
    }
    
    const context = relevantResults
      .map((result, index) => `[Source ${index + 1}] ${result.text}`)
      .join('\n\n');
    
    console.log(`✅ Found ${relevantResults.length} relevant documents (threshold: ${RAG_RELEVANCE_THRESHOLD})`);
    return context;
    
  } catch (error) {
    console.error('❌ Vector store query error:', error);
    return '';
  }
}

/**
 * Get vector store statistics
 * @param {Object} table - LanceDB table instance
 * @returns {Promise<Object>} Statistics object
 */
async function getVectorStoreStats(table) {
  try {
    if (!table) {
      return { error: 'Vector store not initialized' };
    }
    
    const count = await table.countRows();
    return {
      documentCount: count,
      embeddingModel: OLLAMA_EMBEDDING_MODEL,
      dimension: EMBEDDING_DIMENSION,
      storePath: VECTOR_STORE_PATH,
      maxResults: RAG_MAX_RESULTS,
      relevanceThreshold: RAG_RELEVANCE_THRESHOLD
    };
    
  } catch (error) {
    console.error('❌ Failed to get vector store stats:', error);
    return { error: error.message };
  }
}

/**
 * Clear all documents from vector store
 * @param {Object} table - LanceDB table instance
 * @returns {Promise<boolean>} Success status
 */
async function clearVectorStore(table) {
  try {
    if (!table) {
      throw new Error('Vector store not initialized');
    }
    
    // LanceDB doesn't have a direct clear method, so we overwrite with empty table
    const db = await lancedb.connect(VECTOR_STORE_PATH);
    await db.createTable(TABLE_NAME, [], { overwrite: true });
    
    console.log('✅ Vector store cleared');
    return true;
    
  } catch (error) {
    console.error('❌ Failed to clear vector store:', error);
    return false;
  }
}

module.exports = {
  initVectorStore,
  queryVectorStore,
  addDocument,
  getVectorStoreStats,
  clearVectorStore,
  EMBEDDING_DIMENSION,
  OLLAMA_EMBEDDING_MODEL
};