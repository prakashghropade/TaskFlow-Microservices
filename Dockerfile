# ================
# Stage 1 - Dependencies
# ===============

FROM node:20-alpine AS builder

WORKDIR /app

# copy the main  files
COPY package*.json ./

# copy the  applications and shared packages
COPY apps/media-service ./apps
COPY packages/shared ./packages

# install dependencies
RUN npm ci

# Build all Typescript projects
RUN npm run build

# =====================
# Stage 2  Ruuntime
# =====================

FROM node:20-alpine  AS production

WORKDIR /app

# copy the packages files
COPY package*.json ./

# Install productioni dependencies
Run npm ci --omit=dev

# Copy application and shared packages

COPY --from=builder /app/apps ./apps
COPY --from=builder /app/packages ./packages

ARG SERVICE

CMD ["sh", "-c", "npm run start:$SERVICE"]