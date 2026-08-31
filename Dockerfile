# ================================
# Stage 1 - Build
# ================================
FROM node:20-alpine AS builder

WORKDIR /app

# Root package files
COPY package*.json ./

# Copy required workspaces
COPY apps ./apps
COPY packages ./packages

# Install dependencies
RUN npm ci

# Service to build
ARG SERVICE

# Build only selected service
RUN npm run build -w ${SERVICE}


# ================================
# Stage 2 - Runtime
# ================================
FROM node:20-alpine AS production

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./

# Install production dependencies
RUN npm ci --omit=dev

ARG SERVICE

# Copy selected service
COPY --from=builder /app/apps/${SERVICE} ./apps/${SERVICE}

# Copy shared package
COPY --from=builder /app/packages/shared ./packages/shared

# Start selected service
CMD ["sh", "-c", "npm run start -w $SERVICE"]