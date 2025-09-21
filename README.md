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

## 🏗️ Project Architecture
## Full CI/CD Pipeline
```text
                       +-----------------------+
                       |      Developers       |
                       |  git push / PR open   |
                       +-----------+-----------+
                                   |
                                   v
                    +-------------------------------+
                    |     GitHub Actions            |
                    |                               |
   +----------------+-----------------+-------------+---------------------------+
   | Build & Push (on push/PR)        | Deploy (workflow_run after Build & Push)|
   |  - builds ./app Docker image     |   - main -> deploy_base.ps1             |
   |  - pushes to GHCR:               |   - PR   -> deploy_preview.ps1          |
   | (push) ghcr.io/<repo>/web:latest | Cleanup (PR closed)                     |
   | (PR)   ghcr.io/<repo>/web:pr-<n> |   - remove_preview.ps1                  |
   +----------------+-----------------+-----------------------------------------+
                                      |
                                      v
                          (Github self-hosted runner)
    +--------------------------------------------------------------------------+
    |                             Docker Host                                  |
    |                                                                          |
    |  PowerShell scripts:                                                     |
    |   - scripts/deploy_base.ps1                                              |
    |   - scripts/deploy_preview.ps1                                           |
    |   - scripts/remove_preview.ps1                                           |
    |                                                                          |
    |  Pulls images from GHCR                                                  |
    |      (push) ghcr.io/<repo>/web:latest                                    |    
    |      (PR)   ghcr.io/<repo>/web:pr-<n>                                    |    
    |                                                                          |
    |  +------------------ Docker network: webnet ----------------------+      |
    |  |                      +------------------+                      |      |
    |  |                      |   nginx-proxy    |                      |      |
    |  |                      |                  |                      |      |
    |  |                      |   ports 80/443   |                      |      |
    |  |                      +---------+--------+                      |      |
    |  |                                | proxy_pass                    |      |
    |  |             +-----------------------------------+              |      |
    |  |             |                                   |              |      |  
    |  |   +---------v---------+         +---------------v-----------+  |      |   
    |  |   | react-app-main    |         |       web-pr-<n>          |  |      |   
    |  |   |     (main)        |         |  (one per open PR)        |  |      |   
    |  |   | image :latest     |         |      image :pr-<n>        |  |      |   
    |  |   +-------------------+         +---------------------------+  |      |   
    |  +----------------------------------------------------------------+      |
    |                                                                          |
    +--------------------------------------------------------------------------+   
```

## User Interaction Flow

```text
External User (Browser)
    |
    | 1. enters farahelloumi.duckdns.org 
    | or pr-<n>.farahelloumi.duckdns.org
    v
DuckDNS (DNS)
    |
    | 2. resolves host → server public IP
    v
Self-Hosted Server
    |
    v
+------------------+
|    NGINX proxy   |  (routes by hostname)
+--------+---------+
         |
   +-----+-------------------+
   |                         |
   v                         v
react-app-main          web-pr-<n>
(main branch app)       (preview app for PR)
```

## 🔑 Prerequisites
Before using this project, make sure you have the following installed and configured:
1. **Node.js & React**:
- Node.js (v18+ recommended) installed to build the React application.
- npm or yarn for dependency management.

2. **Git**:
- Git installed for version control and to push the React application to the repository.

3. **Docker & GHCR**:
- Docker and Docker Desktop (with WSL for Windows users).
- Docker account (optional if using local registry, required for GHCR).
- GitHub Personal Access Token (PAT) with permissions to push to GHCR.

4. **DuckDNS**:
- DuckDNS account with a registered subdomain.
- Update your DNS to point to your server’s public IP.

## 🌍 DuckDNS Configuration & Port Forwarding
1. Login to DuckDNS
- Go to ```https://www.duckdns.org```.
- Create an account or log in with GitHub / Google / Twitter.
2. Create a DuckDNS Subdomain
- Enter your desired subdomain in the “subdomains” field: example: ```farahelloumi```.
- Click “add domain”.
- Your domain will now be: farahelloumi.duckdns.org
3. Verify Your Public IP
- Open a terminal or browser on your server and check your public IP: curl ifconfig.me
- Note the IP address returned (this is your public IP).
4. Configure Port Forwarding on Your Router
To make your server accessible from the internet:
    1. Log in to your router (in my case, Orange Fixbox) by opening a browser and typing your Default Gateway IP address.
          Open  Command Prompt and type: ```ipconfig``` (on windows) and then look for the Default Gateway IP address.
    2. Log in using the username/password on the sticker of your router (username: admin)     
    3. Go to Advanced Settings → Security → Virtual Server.
    4. Add a new rule:
        - Name: duckdns-http
        - WAN Port: 80-80
        - LAN IP Address: your IPv4 when you tap ipconfig
        - LAN Port: 80-80
        - Protocol: TCP
    5. Add another rule:
        - Name: duckdns-https
        - WAN Port: 443-443
        - LAN IP Address: your IPv4 when you tap ipconfig
        - LAN Port: 443-443
        - Protocol: TCP
    5. Save the settings to apply the configuration.

## ⚙️ HTTPS Configuration:
To generate the certificate and key, the following command was likely used:

```plaintext
sudo mkdir -p /etc/nginx/certs
sudo openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/nginx/certs/nginx-selfsigned.key \
  -out /etc/nginx/certs/nginx-selfsigned.crt
```
- nginx-selfsigned.key → private key
- nginx-selfsigned.crt → certificate
Then, NGINX is configured to use them:
```
ssl_certificate     /etc/nginx/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/nginx/certs/nginx-selfsigned.key;
```

## 🔐 PAT Configuration:
To allow GitHub Actions to push and pull Docker images from GitHub Container Registry (GHCR), you need to create and configure a Personal Access Token (PAT).
1. **Generate a Personal Access Token**
    1. Go to GitHub → Settings → Developer settings → Personal Access Tokens
    2. Click “Tokens (classic)” → Generate new token (classic).
    3. Select the following scopes:
        - ```write:packages``` → required to push images to GHCR.
        - ```read:packages``` → required to pull images from GHCR.
        - ```delete:packages``` → (optional) required for cleanup workflows.
        - ```repo``` → (optional) if you want workflows to also access your repo content.
    4. Click Generate token and copy the token because you won’t be able to see it again.
2. **Add PAT as a GitHub Secret**
    1. Go to your repository on GitHub.
    2. Navigate to: Settings → Secrets and variables → Actions → New repository secret
    3. Add a new secret:
        - Name: ```GHCR_PAT```
        - Value: paste the PAT you generated.
    4. Click Add secret.


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

