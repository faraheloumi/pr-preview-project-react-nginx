# Créer le network Docker s’il n’existe pas déjà
docker network create pr-preview-net --driver bridge 2>$null

# Login GHCR
docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Pull image
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Stop + remove si déjà existant
$containerName = "base-web"

$existing = docker ps -a --filter "name=$containerName" --format "{{.Names}}"
if ($existing -eq $containerName) {
    try {
        docker stop $containerName
    } catch {
        Write-Host "Container $containerName was not running"
    }
    try {
        docker rm $containerName
    } catch {
        Write-Host "Container $containerName could not be removed"
    }
} else {
    Write-Host "No container named $containerName exists"
}

# Run le conteneur
docker run -d --name $containerName --network pr-preview-net ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Reload NGINX
docker exec nginx nginx -s reload
