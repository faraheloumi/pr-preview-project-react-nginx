#!/bin/bash
PR_NUM=$1

docker pull ghcr.io/faraheloumi/react-nginx-pr-preview-pipeline/web:pr-$PR_NUM
docker stop pr-$PR_NUM || true
docker rm pr-$PR_NUM || true
docker run -d --name pr-$PR_NUM --network pr-preview-net ghcr.io/faraheloumi/react-nginx-pr-preview-pipeline/web:pr-$PR_NUM

# Générer conf NGINX
cp nginx/pr-template.conf nginx/sites-enabled/pr-$PR_NUM.conf
sed -i "s/PR_HOSTNAME/pr-$PR_NUM.farahelloumi.duckdns.org/g" nginx/sites-enabled/pr-$PR_NUM.conf
sed -i "s/PR_PORT/80/g" nginx/sites-enabled/pr-$PR_NUM.conf

docker exec nginx nginx -s reload
