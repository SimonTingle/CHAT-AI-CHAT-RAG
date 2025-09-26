const { saveMemory, getMemory } = require('./memory');

async function test() {
  try {
    console.log('Testing memory functions...');
    await saveMemory('test-user', 'test-key', 'test-value');
    console.log('Save successful');
    
    const result = await getMemory('test-user');
    console.log('Retrieved memory:', result);
  } catch (error) {
    console.error('Test failed:', error);
  }
}

test();
