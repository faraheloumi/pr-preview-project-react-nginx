param([string]$PR_NUM)

# Login GHCR
docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Pull image du PR
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM

# Stop + remove si déjà existant
docker stop pr-$PR_NUM 2>$null || echo "no container"
docker rm pr-$PR_NUM 2>$null || echo "no container"

# Run container du PR (ex: map sur port dynamique)
docker run -d --name pr-$PR_NUM --network pr-preview-net ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM

# Générer conf NGINX pour ce PR
Copy-Item nginx\pr-template.conf nginx\sites-enabled\pr-$PR_NUM.conf -Force
(Get-Content nginx\sites-enabled\pr-$PR_NUM.conf) -replace "PRNUMBER", $PR_NUM | Set-Content nginx\sites-enabled\pr-$PR_NUM.conf

# Reload NGINX
docker exec nginx nginx -s reload
