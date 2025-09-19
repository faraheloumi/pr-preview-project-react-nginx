# Vérifier si le network Docker existe déjà
$networkName = "pr-preview-net"
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

# Stop + remove si déjà existant
$containerName = "base-web"
$existing = docker ps -a --filter "name=$containerName" --format "{{.Names}}"
if ($existing -eq $containerName) {
    try { docker stop $containerName } catch { Write-Host "Container $containerName not running" }
    try { docker rm $containerName } catch { Write-Host "Container $containerName could not be removed" }
} else {
    Write-Host "No container named $containerName exists"
}

# Run le conteneur
docker run -d --name $containerName --network $networkName ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Reload NGINX
docker exec nginx nginx -s reload
