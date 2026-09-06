# ================================
# Stage 1 - Build
# ================================
FROM node:20 AS builder

WORKDIR /app

# Root package files
COPY package*.json ./

# Copy applications and shared packages
COPY apps ./apps
COPY packages ./packages
COPY tsconfig.base.json ./

# Install all dependencies
RUN npm ci

# Service to build
ARG SERVICE
ENV SERVICE=${SERVICE}

# Build shared package first
RUN npm run build -w shared

# Build selected service
RUN npm run build -w ${SERVICE}


# ================================
# Stage 2 - Runtime
# ================================
FROM node:20-alpine AS production

WORKDIR /app

ARG SERVICE
ENV SERVICE=${SERVICE}
ENV NODE_ENV=production

# Root package files
COPY package*.json ./

# Copy workspace package.json files
COPY apps/${SERVICE}/package.json ./apps/${SERVICE}/package.json
COPY packages/shared/package.json ./packages/shared/package.json

# Install production dependencies
RUN npm ci --omit=dev

# Copy compiled service
COPY --from=builder /app/apps/${SERVICE}/dist ./apps/${SERVICE}/dist

# Copy compiled shared package
COPY --from=builder /app/packages/shared/dist ./packages/shared/dist

# Start selected service
CMD ["sh", "-c", "npm run start -w $SERVICE"]