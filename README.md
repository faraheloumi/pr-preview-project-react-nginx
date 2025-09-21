# 🚀 CI/CD Pipeline for React App with PR Previews on NGINX using DuckDNS + GHCR + GitHub Actions

## Table of Contents

- [📌 Project Overview](#-project-overview)
- [📁 Directory Structure](#-directory-structure)
- [🏗️ Project Architecture](#%EF%B8%8F-project-architecture)
- [🔑 Prerequisites](#-prerequisites)
- [⚙️ SetUp Instructions](#-setup-instructions)
- [🌍 Domain & HTTPS Setup](#-domain-&-https-setup)
- [🔐 Secrets & Security](#-secrets-&-security)
- [🚀 CI/CD Workflow](#-ci/cd-workflow)
- [🗑️ PR Cleanup Process](#-pr-cleanup-process)
- [📈 Results](#-resultat)
- [🔧 Usage](#-usage)
- [🔮 Future Considerations](#-future-considerations)
- [🤝 Contributing](#-contributing)
- [👨‍💻 Project By](#project-by)

## 📌 Project Overview
This project, developed by Farah Elloumi focuses on implementing a DevOps pipeline for PR previews of a React application using Docker, NGINX, DuckDNS, GitHub Actions, and GitHub Container Registry (GHCR).

The goal is to automatically deploy the base application and every Pull Request (PR) to a public URL, so that UI changes can be reviewed in real time before merging.

The base application and all PR previews are served behind NGINX acting as a reverse proxy, with routing based on subdomains.

For each open PR, a dedicated container image is built in CI, pushed to GHCR, pulled on the server, and served under a unique subdomain.

The base application is served at ```https://username.duckdns.org```, and all PR previews are routed through NGINX as a reverse proxy using subdomains ```https://pr-number.username.duckdns.org```.

On PR merge or close, the preview container and its NGINX route are automatically cleaned up, and the registry tag is deleted.

### 🌟 The project must include:

- 🔄 Automated CI/CD with GitHub Actions.

- 📦 Immutable deployments using container images as the only artifact.

- 🌍 Public and secure previews accessible over HTTPS.

- 🧹 Full lifecycle management (build → deploy → cleanup).

---

## 📁 Directory Structure

```plaintext
project/
│
├─ .github/workflows/                  
│  ├─ build-push.yml                   # GitHub Actions workflow to build and push Docker images to GHCR
│  ├─ cleanup.yml                      # Workflow to remove PR preview containers and clean up registry tags
│  └─ deploy.yml                       # Workflow to deploy the base app and PR previews to the server
│
├─ app/                                # React application (Vite) with Docker + NGINX setup
│  ├─ nginx/                           # NGINX configuration directory
│  │  ├─ sites-enabled/                
│  │  │  ├─ 00-default-http.conf       # Default NGINX config that returns "404 Not Found" for invalid or unmatched URLs
│  │  │  ├─ base.conf                  # NGINX config for the base application
│  │  ├─ templates/
│  │  │  ├─ pr-template.conf           # NGINX config template for PR preview subdomains
│  │  └─ nginx.conf                    # Main NGINX configuration file
│  │
│  ├─ src/                             # React source code
│  │  ├─ App.jsx                       # Main React component
│  │  └─ main.jsx                      # Application entry point
│  │
│  ├─ docker-compose.pr.TEMPLATE.yml   # Docker Compose template for per-PR deployments
│  ├─ docker-compose.yml               # Docker Compose config for the base app deployment
│  ├─ Dockerfile                       # Multi-stage Dockerfile to build React app and serve via NGINX
│  ├─ index.html                       # HTML entry file for the React app
│  ├─ package.json                     # Project dependencies and scripts
│  └─ vite.config.js                   # Vite build and development configuration
│
├─ scripts/                            
│  ├─ deploy_base.ps1                  # PowerShell script to deploy the base application
│  ├─ deploy_preview.ps1               # PowerShell script to deploy a PR preview container
│  └─ remove_preview.ps1               # PowerShell script to remove a PR preview container
│
└─ README.md                           # Project documentation and setup guide

```

## ⚙️ Setup Instructions

### 1️⃣ Local Build & Run
```
# move into app folder
cd app

# install dependencies
npm install
npm install @vitejs/plugin-react --save-dev

# test the react app locally
npm run preview

# build React app
npm run build

# build Docker image
docker build -t pr-preview-demo:latest .

# run locally on port 8080
docker run -d -p 8080:80 pr-preview-demo:latest
```

