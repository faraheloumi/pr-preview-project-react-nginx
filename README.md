# 🚀 CI/CD Pipeline for React App with PR Previews on NGINX using DuckDNS + GHCR + GitHub Actions

## Table of Contents

- [📌 Project Overview](#-project-overview)
- [📁 Directory Structure](#-directory-structure)
- [🏗️ Project Architecture](#%EF%B8%8F-project-architecture)
<!-- - [🔑 Prerequisites](#-prerequisites) -->
- [🌍 DuckDNS Configuration and Port Forwarding](#-duckdns-configuration-and-port-forwarding)
- [⚙️ HTTPS Configuration](#%EF%B8%8F-https-configuration)
- [🔐 PAT Configuration](#-pat-configuration)
- [🖥️ Setup a Self-Hosted GitHub Runner](#%EF%B8%8F-setup-a-self-hosted-github-runner)
- [🔄 Secrets Rotation](#)
- [📈 Results](#-results)
- [🔧 Usage](#-usage)

## 📌 Project Overview
This project, developed by Farah Elloumi focuses on implementing a DevOps pipeline for PR previews of a React application using Docker, NGINX, DuckDNS, GitHub Actions, and GitHub Container Registry (GHCR).

The goal is to automatically deploy the base application and every Pull Request (PR) to a public URL, so that UI changes can be reviewed in real time before merging.

The base application and all PR previews are served behind NGINX acting as a reverse proxy, with routing based on subdomains.

For each open PR, a dedicated container image is built in CI, pushed to GHCR, pulled on the server, and served under a unique subdomain.

The base application is served at ```https://username.duckdns.org```, and all PR previews are routed through NGINX as a reverse proxy using subdomains ```https://pr-number.username.duckdns.org```.

On PR merge or close, the preview container and its NGINX route are automatically cleaned up, and the registry tag is deleted.
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
│  │  │  ├─ 00-default-http.conf       # Default NGINX config: returns "404 Not Found" for invalid URLs
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

<!-- ## 🔑 Prerequisites
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
- Update your DNS to point to your server’s public IP. -->

## 🌍 DuckDNS Configuration and Port Forwarding
1. Login to DuckDNS:
- Go to ```https://www.duckdns.org```.
- Create an account or log in with GitHub / Google / Twitter.
2. Create a DuckDNS Subdomain:
- Enter your desired subdomain in the “subdomains” field: example: ```farahelloumi```.
- Click “add domain”.
- Your domain will now be: farahelloumi.duckdns.org
3. Verify Your Public IP:
- Open a terminal or browser on your server and check your public IP: curl ifconfig.me
- Note the IP address returned (this is your public IP).
4. Create the Auto-Update Script:
- On your host machine, create a folder ```C:\duckdns```.
- Inside, create a file named ```duckdns.ps1``` with the content:
```
$token = "your-token-here"
$domain = "your-domain-here"
Invoke-WebRequest -Uri "https://www.duckdns.org/update?domains=$domain&token=$token&ip=" -UseBasicParsing
```
👉 Replace your-token-here with your DuckDNS token and your-domain-here with your subdomain (e.g., farahelloumi).
5. Test the Script
- Open PowerShell as Administrator.
- Run:
```
cd C:\duckdns
.\duckdns.ps1
```
- If successful, the response will be: **OK**
This confirms that DuckDNS has updated your public IP.
6. Schedule Automatic Updates (Windows Task Scheduler) to ensure your IP is updated regularly:
    1. Open Task Scheduler ```taskschd.msc```.
    2. Click Create Task.
    3. In the General tab:
        - Name: DuckDNS Updater
        - Run whether user is logged on or not.
        - Run with highest privileges.
    4. In the Triggers tab:
        - Add new trigger → Repeat every 5 minutes (or 10–15 min).
    5. In the Actions tab:
        - Action: Start a program.
        - Program/script: ```powershell.exe```
        - Arguments: ```-ExecutionPolicy Bypass -File "C:\duckdns\duckdns.ps1"```
    6. Save the task.
    7. Verify Scheduled Updates
        - Wait a few minutes and check logs in Task Scheduler → History.
7. Configure Port Forwarding on Your Router:
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

1. Comment out SSL in NGINX temporarily:
- In ```app/nginx/sites-enabled/base.conf```, comment out the SSL block and any ```return 301 https://$host$request_uri;``` lines.
- This ensures HTTP requests work for the ACME challenge.
2. Start Docker Compose:
```
docker compose up -d
```
3. Issue the certificate using Certbot:
Run the following command to generate a valid Let's Encrypt certificate:
```
docker run --rm -v letsencrypt:/etc/letsencrypt -v certbot-www:/var/www/certbot certbot/certbot certonly --webroot --webroot-path=/var/www/certbot --email farah.elloumi2000@gmail.com --agree-tos --no-eff-email -d farahelloumi.duckdns.org --non-interactive
```
4. Verify certificate generation:
If ```fullchain.pem``` and ```privkey.pem``` are successfully generated, they will be visible in the terminal.
5. Uncomment SSL in NGINX:
- In ```base.conf```, uncomment the SSL block and the ```return 301 https://$host$request_uri; line```.
6. Reload NGINX:
```
docker exec nginx-proxy nginx -t
docker exec nginx-proxy nginx -s reload
```
7. Test HTTPS:
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
mkdir actions-runner; cd actions-runner

# Download the runner binary
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-win-x64-2.328.0.zip -OutFile actions-runner-win-x64-2.328.0.zip

# Optional: Validate the hash
$ if((Get-FileHash -Path actions-runner-win-x64-2.328.0.zip -Algorithm SHA256).Hash.ToUpper() -ne 'a73ae192b8b2b782e1d90c08923030930b0b96ed394fe56413a073cc6f694877'.ToUpper()){ throw 'Computed checksum did not match' }

# Extract the installer
$ Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.328.0.zip", "$PWD")
```
4. Configure the runner
Run the configuration command provided by GitHub (with your repo and token):
```
$ ./config.cmd --url https://github.com/<username>/<repo> --token <TOKEN>
```
- ```<TOKEN>``` is generated automatically by GitHub when you add a runner.
- You can also set a label (e.g., ```self-hosted```)
5. Start the runner
For Windows (PowerShell or Command Prompt):
```
.\run.cmd
```
You should see in your console that the runner is online.

## 🔄 Secrets Rotation
### PAT Rotation
1. Generate a new PAT:
    - Navigate to GitHub → Settings → Developer settings → Personal access tokens (classic).
    - Click Generate new token.
    - Select the following scopes:
        - write:packages
        - read:packages
        - repo (only required for private repositories)
    - Set an expiration (e.g., 90 days).
    - Copy and store the token securely.
2. Add the new token as a repository secret:
    - Go to Repo → Settings → Secrets and variables → Actions → New repository secret.
    - Add it as ```GHCR_PAT_NEW``` (keep the old GHCR_PAT for now).
3. Test with the new token:
Update your workflow temporarily to use the new secret:
```
- name: Login to GHCR
  uses: docker/login-action@v2
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GHCR_PAT_NEW }}
```
Run a build & push to verify that images are successfully pushed to GHCR.
4. Finalize the rotation
- Delete the old GHCR_PAT secret.
- Rename GHCR_PAT_NEW → GHCR_PAT so your workflows continue working without changes.

### DuckDNS Token Rotation:
1. Log in to DuckDNS (duckdns.org) using the same GitHub/Google/Twitter account you registered the domain with.
2. Open your dashboard, your current token is displayed at the top.
3. Regenerate the token by clicking “regenerate token”.
4. Update your script C://duckdns/duckdns.ps1 with the new token.
5. Test it by running:
```
.\C://duckdns/duckdns.ps1
```

### Let's Encryopt Certificate Rotation:
Let’s Encrypt certificates automatically expire every ~60–90 days. Depending on the situation, follow different procedures:
1. Normal Renewal (keys are valid and intact)

    1. Run a periodic renewal job (e.g., monthly):
    ```
    docker run --rm \
    -v letsencrypt:/etc/letsencrypt \
    -v certbot-www:/var/www/certbot \
    certbot/certbot renew \
        --webroot --webroot-path=/var/www/certbot
    ```
    - If the certificate is not close to expiry, nothing happens.
    - When within ~30 days of expiry, it automatically renews.
    2. Reload NGINX to apply the renewed certificate:
    ```
    docker exec nginx-proxy nginx -s reload
    ```
2. If the Private Key is ***Compromised***
    1. Revoke the old certificate so browsers stop trusting it:
    ```
    docker run --rm \
    -v letsencrypt:/etc/letsencrypt \
    -v certbot-www:/var/www/certbot \
    certbot/certbot revoke \
        --cert-path /etc/letsencrypt/live/farahelloumi.duckdns.org/cert.pem
    ```
    2. Force-issue a brand-new certificate with a new private key:
    ```
    docker run --rm \
    -v letsencrypt:/etc/letsencrypt \
    -v certbot-www:/var/www/certbot \
    certbot/certbot certonly \
        --webroot --webroot-path=/var/www/certbot \
        -d farahelloumi.duckdns.org \
        --force-renewal \
        --email farah.elloumi2000@gmail.com \
        --agree-tos --no-eff-email
    ```
    - ```--force-renewal``` → issue immediately, don’t wait for expiry.
    - A new private key is generated automatically.
    3. Reload NGINX to switch to the new certificate:
    ```
    docker exec nginx-proxy nginx -t && docker exec nginx-proxy nginx -s reload 
    ```
3. If the Private Key is ***Corrupted or Lost***
    - No need to revoke (the key is lost, so no risk).
    - Just force-issue a new certificate and key:
    ```
    docker run --rm \
    -v letsencrypt:/etc/letsencrypt \
    -v certbot-www:/var/www/certbot \
    certbot/certbot certonly \
        --webroot --webroot-path=/var/www/certbot \
        -d farahelloumi.duckdns.org \
        --force-renewal \
        --email farah.elloumi2000@gmail.com \
        --agree-tos --no-eff-email
    ```
    - Reload NGINX:
    ```
    docker exec nginx-proxy nginx -t && docker exec nginx-proxy nginx -s reload
    ```
After completing these steps, your domain farahelloumi.duckdns.org will be served securely with an updated Let’s Encrypt certificate.

## 📈 Results
After setting up this CI/CD pipeline, the following results were achieved:
1. Automated Deployments
    - Every push to the main branch automatically builds a new Docker image, pushes it to GHCR, and deploys it to the server.
    - The base application is always live at: ```https://farahelloumi.duckdns.org```
2. Pull Request Previews
    - Each Pull Request triggers the creation of a dedicated preview environment.
    - A new Docker container is deployed, and NGINX routes traffic using a subdomain: ```http://pr-<number>.farahelloumi.duckdns.org```
    - This allows testing UI changes in real-time before merging.
3. Cleanup Automation
    - When a PR is closed or merged:
        - The corresponding container is automatically removed.
        - The NGINX route is cleaned up.
        - The related image tag is deleted from GHCR.

## 🔧 Usage
Follow these steps to use this project on your own server:
1. Clone the Repository:
```
git clone https://github.com/faraheloumi/pr-preview-project-react-nginx.git
cd pr-preview-project-react-nginx
```
2. Set up a self-hosted GitHub runner as mentioned before, then all workflows will run automatically. Make sure your runner is online in GitHub Actions before pushing any code.
3. Configure Environment Variables:
- Set your GitHub Personal Access Token (PAT) as a repository secret (GHCR_PAT).
- Make sure your DuckDNS subdomain points to your server’s public IP.
4. Create Certificate using Lets Encrypt and follow the steps mentionned before for a valid HTTPS DuckDNS subdomain.
5. Push to main Branch:
- The Main Deployment workflow triggers automatically.
- It builds the Docker image, pushes it to GHCR, and deploys the base container react-app-main via the self-hosted runner.
- The application becomes available at: ```https://<your-subdomain>.duckdns.org```
6. Open a Pull Request (PR):
- Do some changes in the application code and push in another branch example farah in our case.
- Open a Pull Request and the PR Preview workflow will run automatically.
- A Docker image is built and deployed for the PR under the container react-app-pr-<PR_NUMBER>.
- NGINX routes the preview exclusively to: ```http://pr-<PR_NUMBER>.<your-subdomain>.duckdns.org```.
- The base application at ```https://<your-subdomain>.duckdns.org``` remains unchanged and does not reflect the PR changes.
7. Close a Pull Request (PR):
- The Cleanup workflow runs automatically.
- The preview container is stopped and removed.
- The NGINX route is cleaned up.
- The corresponding Docker image is deleted from GHCR.
8. Merge a Pull Request (PR):
- The base application at ```https://<your-subdomain>.duckdns.org``` is updated to include the merged changes.
- The Cleanup workflow runs automatically.
- The preview container is stopped and removed.
- The NGINX route is cleaned up.
- The corresponding Docker image is deleted from GHCR.