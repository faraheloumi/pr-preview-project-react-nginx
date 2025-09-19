$networkName = "pr-preview-net"
$containerName = "base-web"

# Créer le réseau seulement s'il n'existe pas
$existingNetwork = docker network ls --filter "name=$networkName" --format "{{.Name}}"
if (-not $existingNetwork) {
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

if ($existingContainer) {
    # Vérifier s’il est en cours d’exécution
    $runningContainer = docker ps --filter "name=$containerName" --format "{{.Names}}"
    if ($runningContainer) {
        docker stop $containerName
    } else {
        Write-Host "Container $containerName exists but is not running, skipping stop"
    }
    docker rm $containerName
} else {
    Write-Host "No container named $containerName exists, skipping remove"
}

# Run le conteneur
docker run -d --name $containerName --network $networkName ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest
