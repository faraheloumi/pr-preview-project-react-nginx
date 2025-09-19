param([string]$PR_NUM)

# Login GHCR
docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Pull image du PR
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM

# Stop + remove si déjà existant
$PR_CONTAINER = "pr-$PR_NUM"

try {
    docker stop $PR_CONTAINER -ErrorAction Stop
} catch {
    Write-Host "No running container to stop for $PR_CONTAINER"
}

try {
    docker rm $PR_CONTAINER -ErrorAction Stop
} catch {
    Write-Host "No existing container to remove for $PR_CONTAINER"
}

# Run container du PR (ex: map sur port dynamique)
docker run -d --name $PR_CONTAINER --network pr-preview-net ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM

# Générer conf NGINX pour ce PR
$nginxTemplate = "nginx\pr-template.conf"
$nginxTarget = "nginx\sites-enabled\pr-$PR_NUM.conf"

Copy-Item $nginxTemplate $nginxTarget -Force
(Get-Content $nginxTarget) -replace "PRNUMBER", $PR_NUM | Set-Content $nginxTarget

# Reload NGINX
docker exec nginx nginx -s reload
