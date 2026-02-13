# Build stage
FROM node:22-slim AS builder

WORKDIR /app

# Copy dependency files
COPY package*.json ./
COPY tsconfig.json ./

# Install all dependencies (including dev deps for build)
# FR-S1-06: Use npm ci for deterministic builds (OWASP A08)
RUN npm ci

# Copy source and build
COPY src ./src
RUN npm run build

# Production stage
# FR-S4-09: Node.js 22 migration (Node.js 20 EOL 2026-04-30)
FROM node:22-slim

WORKDIR /app

# FR-S1-06: Create non-root user and group
RUN groupadd -r mcp && useradd -r -g mcp -d /app -s /bin/false mcp

# Copy dependency files and install production deps only
COPY package*.json ./
RUN npm ci --omit=dev

# Copy built artifacts from builder
COPY --from=builder /app/dist ./dist

# Create config directory with correct ownership
RUN mkdir -p /app/.google-workspace && \
    chown -R mcp:mcp /app

# FR-S1-06: Switch to non-root user BEFORE declaring VOLUME
USER mcp

# Volume mount point
VOLUME ["/app/.google-workspace"]

# Environment
ENV GOOGLE_CONFIG_DIR=/app/.google-workspace
ENV NODE_ENV=production

# Health check (for orchestration)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD node -e "process.exit(0)"

# Run
CMD ["node", "dist/index.js"]
