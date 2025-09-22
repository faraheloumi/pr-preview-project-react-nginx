# 🚀 CI/CD Pipeline for React App with PR Previews on NGINX using DuckDNS + GHCR + GitHub Actions

## Table of Contents

- [📌 Project Overview](#-project-overview)
- [📁 Directory Structure](#-directory-structure)
- [🏗️ Project Architecture](#%EF%B8%8F-project-architecture)
- [🔑 Prerequisites](#-prerequisites)
- [🌍 DuckDNS Configuration and Port Forwarding](#-duckdns-configuration-and-port-forwarding)
- [⚙️ HTTPS Configuration](#https-configuration)
- [🔐 PAT Configuration](#-pat-configuration)
- [🖥️ Setup a Self-Hosted GitHub Runner](#-setup-a-self-hosted-github-runner)
- [📈 Results](#-resultat)
- [🔧 Usage](#-usage)

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
### Full CI/CD Pipeline
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

### User Interaction Flow

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

## 🌍 DuckDNS Configuration and Port Forwarding
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

## ⚙️ HTTPS Configuration
To enable valid HTTPS using Let’s Encrypt on your self-hosted runner, follow these steps:
1. Prepare persistent directories
In the repository folder on your server, create two directories to store certificates and the ACME webroot:
```
mkdir -p certs/ certbot-www/
```
- certs/ → will hold the Let's Encrypt certificates.
- certbot-www/ → will be used as the ACME webroot for domain validation.
***Tip***: Add both directories to .gitignore to prevent them from being pushed to the repository.
2. Comment out SSL in NGINX temporarily
- In ```app/nginx/sites-enabled/base.conf```, comment out the SSL block and any ```return 301 https://$host$request_uri;``` lines.
- This ensures HTTP requests work for the ACME challenge.
3. Start Docker Compose
```
docker compose up -d
```
4. Issue the certificate using Certbot
Run the following command to generate a valid Let's Encrypt certificate:
```
docker run --rm -v letsencrypt:/etc/letsencrypt -v certbot-www:/var/www/certbot certbot/certbot certonly --webroot --webroot-path=/var/www/certbot --email farah.elloumi2000@gmail.com --agree-tos --no-eff-email -d farahelloumi.duckdns.org --non-interactive
```
5. Verify certificate generation
If ```fullchain.pem``` and ```privkey.pem``` are successfully generated, they will be visible in the Certbot container logs.
6. Uncomment SSL in NGINX
- In ```base.conf```, uncomment the SSL block and the ```return 301 https://$host$request_uri; line```.
7. Reload NGINX
```
docker exec nginx-proxy nginx -t
docker exec nginx-proxy nginx -s reload
```
8. Test HTTPS
- Open your browser and visit:
```
https://farahelloumi.duckdns.org
```
Your site should now be secured with a valid Let's Encrypt certificate.

## 🔐 PAT Configuration
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

## 🖥️ Setup a Self-Hosted GitHub Runner
1. Prepare your server
- Choose a machine (Linux, Windows, or macOS): in my case Windows.
- Install Docker and any other tools required for your workflows.
- Make sure Git is installed.
2. Add a runner in GitHub
    1. Go to your repository on GitHub: Settings → Actions → Runners → New self-hosted runner
    2. Select:
        - OS Window
        - Architecture x64
3. Install the runner
On your server, run the commands provided by GitHub.
```
# Create a folder for the runner
mkdir actions-runner && cd actions-runner  

# Download the runner binary
curl -o actions-runner-linux-x64-2.317.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-x64-2.317.0.tar.gz  

# Extract the package
tar xzf ./actions-runner-linux-x64-2.317.0.tar.gz 
```
4. Configure the runner
Run the configuration command provided by GitHub (with your repo and token):
```
./config.sh --url https://github.com/<username>/<repo> --token <TOKEN>
```
- ```<TOKEN>``` is generated automatically by GitHub when you add a runner.
- You can also set a label (e.g., ```self-hosted```)
5. Start the runner
For Linux/macOS:
```
./run.sh
```
For Windows (PowerShell or Command Prompt):
```
.\run.cmd
```
You should see in your console that the runner is online.

## 📈 Results
After setting up this CI/CD pipeline, the following results were achieved:
1. Automated Deployments
    - Every push to the main branch automatically builds a new Docker image, pushes it to GHCR, and deploys it to the server.
    - The base application is always live at: ```https://farahelloumi.duckdns.org```
2. Pull Request Previews
    - Each Pull Request triggers the creation of a dedicated preview environment.
    - A new Docker container is deployed, and NGINX routes traffic using a subdomain: ```https://pr-<number>.farahelloumi.duckdns.org```
    - This allows testing UI changes in real-time before merging.
3. Cleanup Automation
    - When a PR is closed or merged:
        - The corresponding container is automatically removed.
        - The NGINX route is cleaned up.
        - The related image tag is deleted from GHCR.
4. Secure Access
    - All traffic is routed through NGINX with HTTPS enabled.
    - Public previews can be tested securely from any device.
5. Improved Development Workflow
    - Developers and reviewers can instantly access live previews of PRs.
    - Faster feedback loop and reduced risk of merging breaking UI changes.

## 🔧 Usage
Follow these steps to use this project on your own server:
1. Clone the Repository:
```
git clone https://github.com/faraheloumi/pr-preview-project-react-nginx.git
cd pr-preview-project-react-nginx
```
2. Once the repository is set up with a self-hosted GitHub runner, all workflows run automatically. Make sure your runner is online in GitHub Actions before pushing any code.
3. Configure Environment Variables:
- Set your GitHub Personal Access Token (PAT) as a repository secret (GHCR_PAT).
- Make sure your DuckDNS subdomain points to your server’s public IP.
4. Push to main Branch:
- The Main Deployment workflow triggers automatically.
- It builds the Docker image, pushes it to GHCR, and deploys the base container react-app-main via the self-hosted runner.
- The application becomes available at: ```https://<your-subdomain>.duckdns.org```
5. Open a Pull Request (PR):
- The PR Preview workflow runs automatically when we have changes in our code.
- A Docker image is built and deployed for the PR under the container react-app-pr-<PR_NUMBER>.
- NGINX routes the preview exclusively to: ```https://pr-<PR_NUMBER>.<your-subdomain>.duckdns.org```.
- The base application at ```https://<your-subdomain>.duckdns.org``` remains unchanged and does not reflect the PR changes.
6. Close a Pull Request (PR):
- The Cleanup workflow runs automatically.
- The preview container is stopped and removed.
- The NGINX route is cleaned up.
- The corresponding Docker image is deleted from GHCR.
7. Merge a Pull Request (PR):
- The base application at ```https://<your-subdomain>.duckdns.org``` is updated to include the merged changes.
- The Cleanup workflow runs automatically.
- The preview container is stopped and removed.
- The NGINX route is cleaned up.
- The corresponding Docker image is deleted from GHCR.