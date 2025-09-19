$networkName = "pr-preview-net"
$containerName = "base-web"

# Vérifier si le réseau existe
$existingNetwork = docker network ls --filter "name=$networkName" --format "{{.Name}}"
if ($existingNetwork -ne $networkName) {
    docker network create $networkName --driver bridge
} else {
    Write-Host "Network $networkName already exists"
}

# Login GHCR
docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Pull image
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Vérifier si le container existe
$existingContainer = docker ps -a --filter "name=$containerName" --format "{{.Names}}"
if ($existingContainer -eq $containerName) {
    # Vérifier s’il est en cours d’exécution
    $running = docker ps --filter "name=$containerName" --format "{{.Names}}"
    if ($running -eq $containerName) {
        docker stop $containerName
    } else {
        Write-Host "Container $containerName exists but is not running"
    }
    docker rm $containerName
} else {
    Write-Host "No container named $containerName exists"
}

# Run le conteneur
docker run -d --name $containerName --network $networkName ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Reload NGINX
docker exec nginx nginx -s reload


