const fetch = require('node-fetch');

async function testChat() {
  console.log('🧪 Testing Chat Functionality with Mistral...\n');

  // Test 1: Check Ollama
  console.log('1. Testing Ollama connection...');
  try {
    const ollamaResponse = await fetch('http://localhost:11434/api/tags');
    if (ollamaResponse.ok) {
      const models = await ollamaResponse.json();
      console.log('✅ Ollama is running. Models:', models.models.map(m => m.name));
    } else {
      console.log('❌ Ollama not responding');
      return;
    }
  } catch (error) {
    console.log('❌ Cannot connect to Ollama:', error.message);
    return;
  }

  // Test 2: Test Mistral generate
  console.log('\n2. Testing Mistral generate...');
  try {
    const generateResponse = await fetch('http://localhost:11434/api/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'mistral:7b',
        prompt: 'Say "MISTRAL TEST PASSED" if you can hear me.',
        stream: false
      })
    });
    
    if (generateResponse.ok) {
      const data = await generateResponse.json();
      console.log('✅ Mistral generate works:', data.response);
    } else {
      const errorText = await generateResponse.text();
      console.log('❌ Mistral generate failed:', generateResponse.status, errorText);
    }
  } catch (error) {
    console.log('❌ Mistral generate error:', error.message);
  }

  // Test 3: Test your chat endpoint
  console.log('\n3. Testing your chat endpoint...');
  try {
    const chatResponse = await fetch('http://localhost:3000/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        prompt: 'Hello, please respond with "CHAT WORKING"',
        userId: 'diagnostic-test'
      })
    });
    
    if (chatResponse.ok) {
      const data = await chatResponse.json();
      console.log('✅ Chat endpoint response:', data);
    } else {
      const errorText = await chatResponse.text();
      console.log('❌ Chat endpoint failed:', chatResponse.status, errorText);
    }
  } catch (error) {
    console.log('❌ Chat endpoint error:', error.message);
  }

  console.log('\n🎯 Diagnostic complete.');
}

testChat();
