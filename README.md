# 🚀 React PR Preview Pipeline with NGINX + Docker + GHCR +DuckDns

## 📌 Project Overview
This project implements a CI/CD pipeline to automatically build, deploy, and preview a React application.  
The app is containerized with Docker, served behind **NGINX** with HTTPS via DuckDNS, and deployed through **GitHub Actions**.  
Each Pull Request (PR) generates a **unique public preview URL** so reviewers can validate UI changes before merging.  

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

