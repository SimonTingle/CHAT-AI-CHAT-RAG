FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY backend/package*.json backend/
COPY client/package*.json client/

# Install dependencies
RUN npm run setup

# Copy source code
COPY . .

# Build client
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
