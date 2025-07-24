# syntax=docker.io/docker/dockerfile:1

#=============================================================================
# STAGE 1: IMAGE DE BASE
#=============================================================================
# Utilise Node.js 22 LTS avec Alpine Linux 3.22 (distribution légère ~5MB)
FROM node:22.17.0-alpine3.22 AS base

# Optimisation réseau: Configure des miroirs CDN rapides pour Alpine
# Par défaut Alpine utilise parfois des miroirs lents ou surchargés
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.22/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories && \
    # Met à jour la liste des packages depuis ces nouveaux miroirs
    apk update --no-cache && \
    # Installe dumb-init: gestionnaire de processus léger pour Docker
    # Permet une gestion propre des signaux (SIGTERM, SIGKILL) dans le container
    apk add --no-cache dumb-init && \
    # Nettoie le cache APK pour réduire la taille de l'image
    rm -rf /var/cache/apk/*

#=============================================================================
# STAGE 2: INSTALLATION DES DÉPENDANCES
#=============================================================================
FROM base AS deps
WORKDIR /app

# Copie UNIQUEMENT les fichiers de définition des dépendances
# Cette technique optimise le cache Docker : si package.json n'a pas changé,
# Docker réutilise ce layer en cache
COPY package.json package-lock.json* ./

# Installation des dépendances de production uniquement
# --omit=dev : exclut les devDependencies (économise temps et espace)
# npm ci : installation propre basée sur package-lock.json (plus rapide que npm install)
RUN npm ci --omit=dev

#=============================================================================
# STAGE 3: BUILD DE L'APPLICATION
#=============================================================================
FROM base AS builder  
WORKDIR /app

# Copie les node_modules depuis le stage précédent (réutilise le travail)
COPY --from=deps /app/node_modules ./node_modules
# Copie tout le code source de l'application
COPY . .

# Variables d'environnement pour optimiser le build Next.js
# Désactive la télémétrie Next.js (plus rapide)
ENV NEXT_TELEMETRY_DISABLED=1
# Mode production (optimisations activées)
ENV NODE_ENV=production

# Installation conditionnelle des outils de compilation pour Alpine
# Ces outils sont nécessaires si des packages npm contiennent du code natif (C++)
# || true : continue même si l'installation échoue (ne bloque pas le build)
RUN apk add --no-cache python3 make g++ || true

# Build de l'application Next.js
# Génère les fichiers optimisés dans .next/
RUN npm run build

#=============================================================================
# STAGE 4: IMAGE DE PRODUCTION (RUNTIME)
#=============================================================================
FROM node:22.17.0-alpine3.22 AS runner
WORKDIR /app

# Configuration de l'environnement de production
# Mode production
ENV NODE_ENV=production
# Pas de télémétrie en production
ENV NEXT_TELEMETRY_DISABLED=1
# Port d'écoute par défaut
ENV PORT=3000

# Configuration sécurisée: création d'un utilisateur non-root
RUN apk add --no-cache dumb-init && \
    # Créer un groupe système 'nodejs' avec GID 1001
    addgroup --system --gid 1001 nodejs && \
    # Créer un utilisateur système 'nextjs' avec UID 1001 dans le groupe nodejs
    adduser --system --uid 1001 --ingroup nodejs nextjs

# Copie des fichiers de production depuis le stage builder
# Seuls les fichiers nécessaires à l'exécution sont copiés (optimise la taille)

# Assets statiques
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
# Application buildée
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
# Assets Next.js
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Bascule vers l'utilisateur non-root pour la sécurité
# Le processus Node.js ne s'exécutera pas en tant que root
USER nextjs

# Expose le port 3000 (informatif, ne publie pas automatiquement le port)
EXPOSE 3000

# Point d'entrée avec dumb-init pour une gestion propre des processus
ENTRYPOINT ["dumb-init", "--"]
# Commande par défaut: démarre le serveur Next.js standalone
CMD ["node", "server.js"]

#=============================================================================
# RÉSULTAT: Image finale ~50-100MB (vs ~500MB+ sans optimisations)
# - Sécurisée (utilisateur non-root)
# - Optimisée (multi-stage build)
# - Rapide (cache Docker optimisé)
#=============================================================================