#!/bin/bash
# update_scroll_gpt.sh — Update ModernChat.jsx with auto-scroll and thicker scrollbar

FILE="src/components/ModernChat.jsx"

if [ ! -f "$FILE" ]; then
  echo "Error: $FILE not found!"
  exit 1
fi

echo "Updating $FILE ..."

# 1. Remove duplicate useRef import line
sed -i.bak '/import { useEffect, useRef }/d' "$FILE"

# 2. Add useEffect import to the existing React import line if not already present
if ! grep -q 'useEffect' "$FILE"; then
  sed -i '' 's/import React, { \(.*\) }/import React, { \1, useEffect }/' "$FILE"
fi

# 3. Insert messagesEndRef definition after existing useRef declarations
sed -i '' '/const \[isDragging.*\]/a\
  const messagesEndRef = useRef(null)
' "$FILE"

# 4. Add useEffect to scroll to bottom on messages change
sed -i '' '/const ModernChat = () => {/a\
  useEffect(() => {\
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });\
  }, [messages]);
' "$FILE"

# 5. Add the ref to the messages container div
sed -i '' 's/<div className="flex-1 overflow-y-auto p-4 space-y-4 scrollbar-thin scrollbar-thumb-gray-600 scrollbar-track-gray-800">/<div ref={messagesEndRef} className="flex-1 overflow-y-auto p-4 space-y-4 scrollbar scrollbar-thumb-gray-500 scrollbar-track-gray-800 scrollbar-w-4">/' "$FILE"

echo "Update complete. Original file backed up as ModernChat.jsx.bak"