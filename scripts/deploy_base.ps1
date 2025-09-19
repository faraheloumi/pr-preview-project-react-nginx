# deploy_base.ps1

# Chemin vers le docker-compose.yml
$composeFile = "C:\Users\HP\OneDrive - SUPCOM\Bureau\react-nginx-pr-preview-pipeline-\infra"


# Login GHCR
docker login ghcr.io -u $env:GITHUB_ACTOR -p $env:GHCR_PAT

# Pull les images définies dans le docker-compose
docker-compose -f $composeFile pull

# Lancer tous les services en arrière-plan
docker-compose -f $composeFile up -d