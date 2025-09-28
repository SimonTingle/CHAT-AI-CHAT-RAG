#!/bin/bash

echo "🔍 RUNNING FULL SYSTEM DIAGNOSTICS"
echo "==================================="

echo ""
echo "📁 FILE STRUCTURE CHECK:"
echo "------------------------"
if [ -d "backend" ]; then
    echo "✅ Backend directory exists"
    if [ -f "backend/server.js" ]; then
        echo "✅ server.js found"
        # Check for new endpoints
        if grep -q "app.get('/api/documents'" backend/server.js; then
            echo "✅ Document list endpoint found"
        else
            echo "❌ Document list endpoint missing"
        fi
        if grep -q "app.delete('/api/documents/" backend/server.js; then
            echo "✅ Document delete endpoint found"
        else
            echo "❌ Document delete endpoint missing"
        fi
    else
        echo "❌ server.js not found"
    fi
    
    if [ -f "backend/rag.js" ]; then
        echo "✅ rag.js found"
        if grep -q "userId.*metadata" backend/rag.js; then
            echo "✅ userId tracking in rag.js"
        else
            echo "❌ userId tracking missing in rag.js"
        fi
    else
        echo "❌ rag.js not found"
    fi
else
    echo "❌ Backend directory missing"
fi

if [ -d "client" ]; then
    echo "✅ Client directory exists"
    if [ -f "client/src/components/DocumentManager.jsx" ]; then
        echo "✅ DocumentManager.jsx created"
    else
        echo "❌ DocumentManager.jsx missing"
    fi
    
    if [ -f "client/src/components/ModernChat.jsx" ]; then
        echo "✅ ModernChat.jsx found"
        if grep -q "DocumentManager" client/src/components/ModernChat.jsx; then
            echo "✅ DocumentManager imported"
        else
            echo "❌ DocumentManager import missing"
        fi
        if grep -q "showDocuments" client/src/components/ModernChat.jsx; then
            echo "✅ Document management UI integrated"
        else
            echo "❌ Document management UI missing"
        fi
    else
        echo "❌ ModernChat.jsx not found"
    fi
    
    if [ -f "client/src/services/chatService.js" ]; then
        echo "✅ chatService.js found"
        if grep -q "listDocuments\|deleteDocument" client/src/services/chatService.js; then
            echo "✅ Document management methods added"
        else
            echo "❌ Document management methods missing"
        fi
    else
        echo "❌ chatService.js not found"
    fi
else
    echo "❌ Client directory missing"
fi

echo ""
echo "🔧 BACKEND ENDPOINT TEST:"
echo "-------------------------"
if nc -z localhost 3001 2>/dev/null; then
    echo "✅ Backend server appears to be running on port 3001"
    
    # Test if endpoints exist (non-invasive check)
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/health | grep -q "200\|40"; then
        echo "✅ Backend health endpoint accessible"
    else
        echo "⚠️  Backend health check failed"
    fi
else
    echo "❌ Backend server not running on port 3001"
    echo "   Please start with: cd backend && node server.js"
fi

echo ""
echo "🌐 FRONTEND STATUS:"
echo "-------------------"
if nc -z localhost 5173 2>/dev/null; then
    echo "✅ Frontend server appears to be running on port 5173"
else
    echo "❌ Frontend server not running on port 5173"
    echo "   Please start with: cd client && npm run dev"
fi

echo ""
echo "📋 BACKUP STATUS:"
echo "-----------------"
BACKUP_COUNT=$(ls -d backup_* 2>/dev/null | wc -l | tr -d ' ')
if [ "$BACKUP_COUNT" -gt 0 ]; then
    echo "✅ $BACKUP_COUNT backup(s) found"
    ls -d backup_* | head -3
else
    echo "❌ No backups found"
fi

echo ""
echo "🚀 UPDATE STATUS:"
echo "-----------------"
if [ -f "update_dragdrop_gwen.sh" ]; then
    echo "✅ update_dragdrop_gwen.sh script exists"
    if [ -x "update_dragdrop_gwen.sh" ]; then
        echo "✅ Script is executable"
    else
        echo "❌ Script is not executable"
    fi
else
    echo "❌ update_dragdrop_gwen.sh not found"
fi

echo ""
echo "📋 RECOMMENDED ACTIONS:"
echo "----------------------"
echo "1. Start backend:  cd backend && node server.js"
echo "2. Start frontend: cd client && npm run dev" 
echo "3. Open http://localhost:5173"
echo "4. Test drag & drop functionality"
echo "5. Check browser console for debugging messages"
echo "6. Use 'Show Docs' button to manage documents"

