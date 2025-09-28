#!/bin/bash
echo "🛑 Stopping all services..."
kill -9 $(lsof -ti:3000) 2>/dev/null || true
kill -9 $(lsof -ti:5173) 2>/dev/null || true

echo "🚀 Starting services..."
# Start backend
cd backend
node server.js &
BACKEND_PID=$!

# Start frontend  
cd ../client
npm run dev &
FRONTEND_PID=$!

echo "✅ Backend PID: $BACKEND_PID"
echo "✅ Frontend PID: $FRONTEND_PID"
echo "📊 Services restarting..."
