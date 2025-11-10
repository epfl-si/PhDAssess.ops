# Stage 1: Build
ARG BASE_IMAGE=node:22-alpine

FROM $BASE_IMAGE AS builder

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json first to leverage caching
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy all TypeScript files
COPY . .

# Build TypeScript
RUN npm run build

# Stage 2: Production image
FROM $BASE_IMAGE

# Set working directory
WORKDIR /app

# Copy package.json (to install production dependencies)
COPY package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev

# Copy compiled files from builder
COPY --from=builder /app/dist ./dist

# Set environment variables (can be overridden in OpenShift)
ENV ZEEBE_API_URL=http://zeebe:9600
ENV POLL_INTERVAL_MS=10000
ENV MAX_POLL_MINUTES=10

# Set default command
CMD ["node", "dist/backup.js"]
