# Créer le network Docker s’il n’existe pas déjà
docker network create pr-preview-net --driver bridge 2>$null

# Login GHCR
docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Pull et lancer container base
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Stop + remove si déjà existant
docker stop base-web 2>$null || echo "no container"
docker rm base-web 2>$null || echo "no container"

# Run le conteneur de base (port 3000 -> 3000 ou autre selon ton app)
docker run -d --name base-web --network pr-preview-net ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Reload NGINX
docker exec nginx nginx -s reload
