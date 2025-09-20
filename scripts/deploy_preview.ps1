param([string]$PR_NUM)

docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Générer .env avec le tag PR
Set-Content ../app/.env "IMAGE_TAG=pr-$PR_NUM"

# Générer la conf Nginx spécifique à la PR
(Get-Content ../app/nginx/pr-template.conf) -replace "PRNUMBER", $PR_NUM | Set-Content ../app/nginx/sites-enabled/pr-$PR_NUM.conf

# Pull image PR
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM

# Lancer les conteneurs
docker compose -f ../app/docker-compose.yml --env-file ../app/.env up -d

# Recharger Nginx pour appliquer la nouvelle conf
docker exec nginx-proxy-duckdns nginx -s reload



# Stop + remove si déjà existant
# $PR_CONTAINER = "pr-$PR_NUM"
# try { docker stop $PR_CONTAINER } catch { Write-Host "No running container for $PR_CONTAINER" }
# try { docker rm $PR_CONTAINER } catch { Write-Host "No existing container for $PR_CONTAINER" }

# Run container du PR
# docker run -d --name $PR_CONTAINER --network pr-preview-net ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM

# # Générer conf NGINX pour ce PR
# $nginxTemplate = "nginx\pr-template.conf"
# $nginxTarget = "nginx\sites-enabled\pr-$PR_NUM.conf"
# Copy-Item $nginxTemplate $nginxTarget -Force
# (Get-Content $nginxTarget) -replace "PRNUMBER", $PR_NUM | Set-Content $nginxTarget

# # Reload NGINX
# docker exec nginx-proxy-duckdns nginx -s reload