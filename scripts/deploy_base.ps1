# Créer le network Docker s’il n’existe pas déjà
docker network create pr-preview-net --driver bridge -ErrorAction SilentlyContinue

# Login GHCR
docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Pull l'image de base
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Stop + remove container base si déjà existant
try {
    docker stop base-web -ErrorAction Stop
} catch {
    Write-Host "No running container to stop for base-web"
}

try {
    docker rm base-web -ErrorAction Stop
} catch {
    Write-Host "No existing container to remove for base-web"
}

# Run le conteneur de base
docker run -d --name base-web --network pr-preview-net ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Reload NGINX
docker exec nginx nginx -s reload
