# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Production stage
FROM caddy:2-alpine

# Copy built files to Caddy
COPY --from=build /app/dist /usr/share/caddy

# Copy Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

# Expose port
EXPOSE 80

# Start Caddy
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]