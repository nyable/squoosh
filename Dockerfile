# Stage 1: Build the application
FROM node:20.16.0-alpine AS builder

WORKDIR /app

# Install dependencies required for build
# python3, make, g++ are often needed for native modules (though squoosh uses pre-built WASM mostly, node-gyp might need them)
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Serve using Nginx
FROM nginx:alpine-slim

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy build artifacts from builder stage (the build script moves output to 'build' folder)
COPY --from=builder /app/build /usr/share/nginx/html

# Clean up unnecessary files to reduce image size
RUN find /usr/share/nginx/html -name "*.map" -type f -delete && \
    find /usr/share/nginx/html -name "*.d.ts" -type f -delete

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
