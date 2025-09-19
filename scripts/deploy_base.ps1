# Créer network Docker si pas existant
docker network create pr-preview-net -ErrorAction SilentlyContinue

# Pull et lancer container base
docker pull ghcr.io/<user>/<repo>/web:latest
docker stop base-web -ErrorAction SilentlyContinue
docker rm base-web -ErrorAction SilentlyContinue
docker run -d --name base-web --network pr-preview-net ghcr.io/<user>/<repo>/web:latest

# Reload NGINX
docker exec nginx nginx -s reload
