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
This project implements a DevOps pipeline for PR previews of a React application using Docker, NGINX, DuckDNS, GitHub Actions, and GitHub Container Registry (GHCR).

The goal is to automatically deploy the base application and every Pull Request (PR) to a public URL, so that UI changes can be reviewed in real time before merging.

The base application is deployed at a public DuckDNS domain secured with HTTPS (Let’s Encrypt).

For each open PR, a dedicated container image is built in CI, pushed to GHCR, pulled on the server, and served under a unique subdomain (e.g., https://pr-17.username.duckdns.org).

On PR merge or close, the preview container and its NGINX route are automatically cleaned up, and the registry tag is deleted.

This setup ensures:

- 🔄 Automated CI/CD with GitHub Actions.

- 📦 Immutable deployments using container images as the only artifact.

- 🌍 Public and secure previews accessible over HTTPS.

- 🧹 Full lifecycle management (build → deploy → cleanup).

---

## 📁 Directory Structure

```plaintext
project/
├─ app/ # React app (Vite)
│ ├─ Dockerfile # Multi-stage build (Node + NGINX)
│ ├─ index.html
│ ├─ package.json
│ ├─ vite.config.js
│ └─ src/ # React source code
│ ├─ App.jsx
│ └─ main.jsx
│
├─ nginx/ # NGINX configuration files
│ ├─ nginx.conf
│ ├─ base.conf # Base site (yourname.duckdns.org, HTTPS)
│ └─ pr-template.conf # Template for PR previews
│
├─ scripts/ # Deployment scripts
│ ├─ deploy_base.sh
│ ├─ deploy_preview.sh
│ └─ remove_preview.sh
│
└─ .github/workflows/ # CI/CD workflows
│
├─ build-and-deploy.yml
│
└─ cleanup.yml
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

