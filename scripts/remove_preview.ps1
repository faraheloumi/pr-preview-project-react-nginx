param([string]$PR_NUM)

# Stop container si existe
Try {
    docker stop "web-pr-$PR_NUM" | Out-Null
} Catch {
    Write-Host "Container web-pr-$PR_NUM does not exist or cannot be stopped."
}

# Remove container si existe
Try {
    docker rm "web-pr-$PR_NUM" | Out-Null
} Catch {
    Write-Host "Container web-pr-$PR_NUM does not exist or cannot be removed."
}

# Remove nginx conf si existe
$confPath = "nginx\sites-enabled\pr-$PR_NUM.conf"
If (Test-Path $confPath) {
    Remove-Item $confPath
}

# Reload nginx (ignore si container nginx n'existe pas)
Try {
    docker exec nginx nginx -s reload | Out-Null
} Catch {
    Write-Host "Nginx container does not exist or cannot reload."
}

# Remove docker image si existe
Try {
    docker rmi "ghcr.io/faraheloumi/pr-preview-project-react-nginx/web:pr-$PR_NUM" | Out-Null
} Catch {
    Write-Host "Image pr-$PR_NUM does not exist or cannot be removed."
}