param([string]$PR_NUM)

docker pull ghcr.io/<user>/<repo>/web:pr-$PR_NUM
docker stop pr-$PR_NUM -ErrorAction SilentlyContinue
docker rm pr-$PR_NUM -ErrorAction SilentlyContinue
docker run -d --name pr-$PR_NUM --network pr-preview-net ghcr.io/<user>/<repo>/web:pr-$PR_NUM

# Générer conf NGINX pour le PR
Copy-Item nginx\pr-template.conf nginx\sites-enabled\pr-$PR_NUM.conf
(Get-Content nginx\sites-enabled\pr-$PR_NUM.conf) -replace "PRNUMBER", $PR_NUM | Set-Content nginx\sites-enabled\pr-$PR_NUM.conf

# Reload NGINX
docker exec nginx nginx -s reload
