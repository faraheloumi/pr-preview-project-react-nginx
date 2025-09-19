#!/bin/bash
PR_NUM=$1
docker stop pr-$PR_NUM || true
docker rm pr-$PR_NUM || true
rm -f nginx/sites-enabled/pr-$PR_NUM.conf
docker exec nginx nginx -s reload
docker rmi ghcr.io/faraheloumi/react-nginx-pr-preview-pipeline/web:pr-$PR_NUM || true
