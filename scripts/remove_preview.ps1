param([string]$PR_NUM)

docker stop web-pr-$PR_NUM -ErrorAction SilentlyContinue
docker rm web-pr-$PR_NUM -ErrorAction SilentlyContinue
Remove-Item nginx\sites-enabled\pr-$PR_NUM.conf -ErrorAction SilentlyContinue
docker exec nginx nginx -s reload
docker rmi ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM -ErrorAction SilentlyContinue
