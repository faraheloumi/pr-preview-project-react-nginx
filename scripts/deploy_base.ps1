$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

$ComposeFile = Join-Path $RepoRoot "app\docker-compose.yml"

docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest

docker compose -f $ComposeFile up -d

docker exec nginx-proxy nginx -t

docker exec nginx-proxy nginx -s reload

echo "✅ Main deployed: https://farahelloumi.duckdns.org" 