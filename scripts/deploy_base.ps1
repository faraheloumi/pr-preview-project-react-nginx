docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Générer .env avec le tag latest
Set-Content ../app/.env "IMAGE_TAG=latest"

# Copier la conf Nginx prod
Copy-Item ../app/nginx/sites-enabled/base.conf ../app/nginx/sites-enabled/base.conf -Force

# Pull image latest
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

# Lancer les conteneurs
docker compose -f ../app/docker-compose.yml --env-file ../app/.env up -d

# Recharger Nginx pour appliquer la nouvelle conf
docker exec nginx-proxy nginx -s reload





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


