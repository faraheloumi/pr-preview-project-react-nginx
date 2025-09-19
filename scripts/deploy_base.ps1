# Créer le network Docker s’il n’existe pas déjà
docker network create pr-preview-net --driver bridge 2>$null

# Login GHCR
docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Pull et lancer container base
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Stop + remove si déjà existant
try { docker stop base-web } catch { Write-Host "No container to stop" }
try { docker rm base-web } catch { Write-Host "No container to remove" }

# Run le conteneur de base
docker run -d --name base-web --network pr-preview-net ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Reload NGINX
docker exec nginx nginx -s reload
