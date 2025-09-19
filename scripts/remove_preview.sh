#!/bin/bash
PR_NUM=$1
docker stop pr-$PR_NUM || true
docker rm pr-$PR_NUM || true
rm -f nginx/sites-enabled/pr-$PR_NUM.conf
docker exec nginx nginx -s reload
docker rmi ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM || true
