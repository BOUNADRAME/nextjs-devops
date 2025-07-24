# syntax=docker.io/docker/dockerfile:1

# Utiliser Node.js 22 LTS Alpine - version sécurisée
FROM node:22.17.0-alpine3.22 AS base

# Mise à jour sécurisée minimale + outils pour les binaires natifs
RUN apk update && apk upgrade && \
    apk add --no-cache \
    dumb-init \
    python3 \
    make \
    g++ \
    libc6-compat && \
    rm -rf /var/cache/apk/*

# Stage des dépendances
FROM base AS deps
WORKDIR /app

# Copier package files
COPY package.json package-lock.json* ./

# Installation des dépendances (incluant dev pour le build)
RUN npm ci

# Stage de build
FROM base AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

RUN npm run build

# Stage de production
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000

# Créer utilisateur simple
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 --ingroup nodejs nextjs

# Copier les fichiers nécessaires
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]