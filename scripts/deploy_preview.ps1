param([string]$PR_NUM)

docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

$RepoRoot        = Split-Path -Parent $PSScriptRoot

# Compose templates/files
$TemplateCompose = Join-Path $RepoRoot "app\docker-compose.pr.TEMPLATE.yml"
$WorkCompose     = Join-Path $RepoRoot ("app\docker-compose.pr.{0}.yml" -f $PR_NUM)

# NGINX site template now lives OUTSIDE sites-enabled (so nginx doesn't parse it directly)
$TemplateSiteDir = Join-Path $RepoRoot "app\nginx\templates"
$TemplateSite    = Join-Path $TemplateSiteDir "pr-template.conf"

# Real vhost files go under sites-enabled (mounted into the nginx container)
$SitesEnabledDir = Join-Path $RepoRoot "app\nginx\sites-enabled"
$WorkSite        = Join-Path $SitesEnabledDir ("pr-{0}.conf" -f $PR_NUM) 

# Replace PRNUMBER in compose template 
(Get-Content $TemplateCompose )  -replace "PRNUMBER", $PR_NUM  |  Set-Content $WorkCompose

# Replace PRNUMBER in pr-template.conf
(Get-Content $TemplateSite)  -replace "PRNUMBER", $PR_NUM  |  Set-Content $WorkSite

# Pull image PR
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM

# Lancer les conteneurs
docker compose -f $WorkCompose up -d

docker exec nginx-proxy nginx -t

# Recharger Nginx pour appliquer la nouvelle conf
docker exec nginx-proxy nginx -s reload

echo "✅ Preview deployed: https://pr-${PR_NUM}.farahelloumi.duckdns.org" 



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