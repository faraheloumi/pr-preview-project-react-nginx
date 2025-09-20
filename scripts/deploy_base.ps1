# Login GHCR
docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Pull image
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

docker compose -f ../app/docker-compose.yml up -d



# Vérifier si le container existe
# $existingContainer = docker ps -a --filter "name=$containerName" --format "{{.Names}}"

# if ($existingContainer) {
#     # Si le container existe mais n'est pas en cours d'exécution, le démarrer
#     $runningContainer = docker ps --filter "name=$containerName" --format "{{.Names}}"
#     if (-not $runningContainer) {
#         docker start $containerName
#         Write-Host "Container $containerName started"
#     } else {
#         Write-Host "Container $containerName is already running"
#     }
# } else {
#     # Si le container n'existe pas, le créer et le lancer
#     docker run -d --name $containerName --network $networkName ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest
#     Write-Host "Container $containerName created and started"
# }


