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

docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM

docker compose -f $WorkCompose up -d

docker exec nginx-proxy nginx -t

docker exec nginx-proxy nginx -s reload

echo "✅ Preview deployed: https://pr-${PR_NUM}.farahelloumi.duckdns.org" 