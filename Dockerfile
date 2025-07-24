# syntax=docker.io/docker/dockerfile:1

# Alpine avec miroir spécifique pour éviter les lenteurs réseau
FROM node:22.17.0-alpine3.22 AS base

# Changer de miroir Alpine + installation rapide
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.22/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories && \
    apk update --no-cache && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# Stage des dépendances
FROM base AS deps
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

# Stage de build
FROM base AS builder  
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Si erreur lightningcss, installer uniquement les outils nécessaires
RUN apk add --no-cache python3 make g++ || true
RUN npm run build

# Stage de production
FROM node:22.17.0-alpine3.22 AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000

RUN apk add --no-cache dumb-init && \
    addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 --ingroup nodejs nextjs

COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]