#!/bin/bash
docker network create pr-preview-net || true
docker pull ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest
docker stop base-web || true
docker rm base-web || true
docker run -d --name base-web --network pr-preview-net ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:latest
docker exec nginx nginx -s reload