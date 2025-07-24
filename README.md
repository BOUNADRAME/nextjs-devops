# 🚀 Bootcamp DevOps - Next.js Application

Application Next.js 15 containerisée avec Docker, optimisée pour la production.

## 📋 Prérequis

- [Docker](https://docs.docker.com/get-docker/) installé
- [Docker Compose](https://docs.docker.com/compose/install/) (optionnel)
- Node.js 22+ (pour le développement local)

## 🏗️ Construction de l'image

### Build standard

```bash
docker build -t bootcamp-ui:1.0.0 .
```

### Build avec mesure du temps

```bash
time docker build -t bootcamp-ui:1.0.0 .
```

### Build avec détails complets

```bash
docker build --progress=plain -t bootcamp-ui:1.0.0 .
```

### Build sans cache (test de performance)

```bash
docker build --no-cache -t bootcamp-ui:1.0.0 .
```

## 🚢 Déploiement

### Avec Docker

```bash
# Lancer le container
docker run -d \
  --name bootcamp-app \
  -p 3000:3000 \
  -e NODE_ENV=production \
  bootcamp-ui:1.0.0

# Vérifier les logs
docker logs bootcamp-app

# Arrêter le container
docker stop bootcamp-app
docker rm bootcamp-app
```

### Avec Docker Compose

```bash
# Démarrer l'application
docker compose up -d

# Voir les logs en temps réel
docker compose logs -f

# Arrêter l'application
docker compose down
```

## 🌐 Accès à l'application

Une fois déployée, l'application est accessible sur :

- **URL locale** : http://localhost:3000

## 📁 Structure du projet

```
├── Dockerfile              # Configuration Docker multi-stage
├── docker-compose.yml      # Configuration Docker Compose
├── .dockerignore           # Fichiers exclus du build Docker
├── package.json            # Dépendances Node.js
├── next.config.js          # Configuration Next.js
├── app/                    # Code source Next.js 15
└── public/                 # Assets statiques
```

## 🔧 Configuration

### Variables d'environnement

| Variable                  | Description               | Valeur par défaut |
| ------------------------- | ------------------------- | ----------------- |
| `NODE_ENV`                | Environnement d'exécution | `production`      |
| `PORT`                    | Port d'écoute             | `3000`            |
| `NEXT_TELEMETRY_DISABLED` | Désactive la télémétrie   | `1`               |

### Exemple de configuration

```bash
# .env.local (pour le développement)
NODE_ENV=development
PORT=3000
```

## 🐛 Débogage

### Vérifier l'état du container

```bash
# Lister les containers
docker ps

# Inspecter le container
docker inspect bootcamp-app

# Accéder au shell du container
docker exec -it bootcamp-app sh
```

### Analyser l'image Docker

```bash
# Voir l'historique des layers
docker history bootcamp-ui:1.0.0

# Analyser la taille de l'image
docker images | grep bootcamp-ui

# Scanner les vulnérabilités (avec Trivy)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image bootcamp-ui:1.0.0
```

## ⚡ Optimisations

### Taille de l'image

- **Multi-stage build** : Sépare build et runtime
- **Alpine Linux** : Distribution légère (~5MB base)
- **Standalone output** : Bundle Next.js autonome
- **Production deps only** : Exclut les devDependencies

### Sécurité

- **Utilisateur non-root** : Processus avec UID/GID 1001
- **Minimal attack surface** : Seulement les binaires nécessaires
- **Process manager** : dumb-init pour gestion des signaux

### Performance

- **Cache Docker optimisé** : Layers réutilisables
- **CDN mirrors** : Miroirs Alpine rapides
- **Télémétrie désactivée** : Build et runtime plus rapides

## 📊 Métriques

### Temps de build attendus

- **Premier build** : 3-8 minutes
- **Build avec cache** : 1-3 minutes
- **Code uniquement modifié** : 30s-1min

### Taille de l'image

- **Image finale** : ~50-100MB
- **Sans optimisations** : 500MB+

## 🚨 Dépannage

### Problèmes courants

**Build lent sur Alpine**

```bash
# Essayer la version Debian
FROM node:22.17.0-bookworm-slim AS base
```

**Erreur lightningcss**

```bash
# Installer les outils de compilation
RUN apk add --no-cache python3 make g++
```

**Permissions refusées**

```bash
# Vérifier les permissions
docker exec -it bootcamp-app whoami
docker exec -it bootcamp-app ls -la
```

## 📚 Ressources

- [Documentation Next.js](https://nextjs.org/docs)
- [Best practices Docker](https://docs.docker.com/develop/dev-best-practices/)
- [Node.js Docker Guide](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

---

**📧 Support** : Pour toute question, ouvrir une issue sur le repository.
