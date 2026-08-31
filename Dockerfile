# ================
# Stage 1 - Dependencies
# ===============

FROM node:20-alpine AS builder

WORKDIR /app

# copy the main  files
COPY package*.json ./

# copy the  applications and shared packages
COPY apps/media-service ./apps
COPY packages/shared ./packages/shared

# install dependencies
RUN npm ci

ARG SERVICE

RUN npm run build -w ${SERVICE}

# =====================
# Stage 2  Ruuntime
# =====================

FROM node:20-alpine  AS production

WORKDIR /app

# copy the packages files
COPY package*.json ./

# Install productioni dependencies
Run npm ci --omit=dev

ARG SERVICE

# Copy application and shared packages
COPY --from=builder /app/apps/${SERVICE} ./apps/${SERVICE}
COPY --from=builder /app/packages ./packages


CMD ["sh", "-c", "npm run start:$SERVICE"]