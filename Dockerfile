FROM oven/bun:1-alpine AS base

FROM base AS builder
# Set working directory
WORKDIR /app
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat

# Copy repo
COPY . .

# Install dependencies and build
RUN bun install
RUN bun run build

# Production image, copy all the files and run next
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# OpenShift recommended security context - assign arbitrary UID but group 0
# Create non-root user for local docker usage (OpenShift overrides this but uses the group permissions)
RUN addgroup -S nodejs -g 1001 && adduser -S nextjs -u 1001 -G nodejs

# Automatically leverage output traces to reduce image size
# Copy standalone Next.js server
COPY --from=builder --chown=1001:0 /app/apps/editor/.next/standalone ./
# Copy static files (these are not copied by default to standalone)
COPY --from=builder --chown=1001:0 /app/apps/editor/.next/static ./apps/editor/.next/static
COPY --from=builder --chown=1001:0 /app/apps/editor/public ./apps/editor/public

# Set proper permissions for OpenShift (arbitrary UID support)
# Group 0 needs write access to any directory the app might write to at runtime
RUN chgrp -R 0 /app && \
    chmod -R g=u /app

USER 1001

EXPOSE 3000

ENV PORT=3000
# set hostname to localhost
ENV HOSTNAME="0.0.0.0"

# Note: The standalone output recreates the monorepo structure.
CMD ["node", "apps/editor/server.js"]
