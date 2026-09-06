# ================================
# Stage 1 - Build
# ================================
FROM node:20 AS builder

WORKDIR /app

# Root package files
COPY package.json package-lock.json ./

# Copy applications and shared packages
COPY apps ./apps
COPY packages ./packages
COPY tsconfig.base.json ./ 

# Service to build
ARG SERVICE
ENV SERVICE=${SERVICE}

# Install dependencies after all workspace manifests are available.
RUN npm ci

# Build the shared package first because services resolve its compiled exports.
RUN npm run build -w shared

# Build the selected service.
RUN npm run build -w ${SERVICE}


# ================================
# Stage 2 - Runtime
# ================================
FROM node:20-alpine AS production

WORKDIR /app

ARG SERVICE

ENV SERVICE=${SERVICE}

# Root package files
COPY package.json package-lock.json ./
COPY apps ./apps
COPY packages ./packages

# Install production dependencies
RUN npm ci --omit=dev

# Copy compiled output for the selected service and shared package.
COPY --from=builder /app/apps/${SERVICE}/dist ./apps/${SERVICE}/dist
COPY --from=builder /app/packages/shared ./packages/shared

# Start the compiled service without requiring dev-only tooling such as tsx.
CMD ["sh", "-c", "node apps/$SERVICE/dist/index.js"]