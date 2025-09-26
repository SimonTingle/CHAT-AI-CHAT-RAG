#!/bin/bash

echo "Setting up Chat AI RAG project..."

# Install root dependencies
echo "Installing root dependencies..."
npm install

# Install backend dependencies
echo "Installing backend dependencies..."
cd backend
npm install express socket.io sqlite3 dotenv cors uuid
cd ..

# Install client dependencies
echo "Installing client dependencies..."
cd client
npm install
cd ..

# Create .env file for backend
echo "Creating backend .env file..."
cd backend
if [ ! -f .env ]; then
    echo "PORT=3001" > .env
    echo "NODE_ENV=development" >> .env
fi
cd ..

echo "Setup complete! Run 'npm run dev' to start the development server."


