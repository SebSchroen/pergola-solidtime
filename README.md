# Solidtime Time Tracker on Pergola

This repository contains the configuration and playbooks used to successfully migrate and deploy the open-source time-tracking application **Solidtime** onto [Pergola](https://pergola.cloud/), a containerized application deployment platform.

Historically managed via Docker Compose, you can reference the official [Solidtime Self-Hosting Docker Guide](https://docs.solidtime.io/self-hosting/guides/docker) for baseline parameters. In this repository, the application has been containerized and structured to deploy dynamically across Pergola stages using [`pergola.yaml`](pergola.yaml).

---

## Local Preparation: Generating Secrets with Docker Compose

Before deploying to Pergola, you should spin up the project locally once using the existing [`docker-compose.yml`](docker-compose.yml) file. This initializes the stack and generates the required cryptographic configurations and application key credentials inside your local `.env` and `laravel.env` files, which are then used in stage configuration setup.

To run the local compose and generate configuration files:

```bash
# 1. Copy the environment templates
cp .env.example .env
cp laravel.env.example laravel.env

# 2. Start the local containers using Docker Compose
docker compose up -d

# 3. Generate the Laravel application key if not set
docker compose exec app php artisan key:generate

# 4. Generate the Passport cryptographic keys
docker compose exec app php artisan passport:keys --force
```

Once generated, retrieve these values from your locally populated `laravel.env` and `.env` files to bind them to your Pergola stage configurations in the steps below.

---
## Architecture Overview
The Solidtime application stack is divided into five main components defined in [`pergola.yaml`](pergola.yaml):
| Service / Component | Role | Runtime / Image | Storage / Volume | Exposure / Network |
| :--- | :--- | :--- | :--- | :--- |
| **`app`** | Web service & API engine | `solidtime/solidtime:latest` | `app-strg` (500Mi at `/var/www/html/storage/app`) | Publicly exposed via ingress |
| **`scheduler`** | Scheduled task manager (Cron) | `solidtime/solidtime:latest` | `scheduler-strg` (500Mi at `/var/www/html/storage/app`) | Internal only |
| **`queue`** | Background queue job consumer | `solidtime/solidtime:latest` | `queue-strg` (500Mi at `/var/www/html/storage/app`) | Internal only |
| **`database`** | Relational Database backend | `postgres:15` | `database-storage` (1Gi at `/var/lib/postgresql/data`) | Internal only |
| **`gotenberg`** | PDF generation service | `gotenberg/gotenberg:8` | None (Stateless) | Internal only |
### Environment Isolation & Service Discovery
* **Config Ref bindings:** Sensitive variables are loaded dynamically on release via Stage Config variables (`config-ref`), keeping the manifest clean.
* **Component-ref linking:** Services discover each other internally via automated DNS (e.g. `DB_HOST` links to `database` through a `component-ref`).
---
## Deployment Steps & Run Guide
To get Solidtime up and running on Pergola, follow the steps below.
### 1. Project and Stage Initialization
Create the project in Pergola and link it to your version-controlled repository (Option A), or set up a placeholder project referencing a public repository (Option B).
```bash
# 1. Initialize project container in Pergola
pergola create project pergola-solidtime \
  --git-url git@github.com:your-github-username/pergola-solidtime.git \
  --display-name "Solidtime Time Tracker"
# 2. View/Retrieve the SSH Deploy Key to authorize access in GitHub/GitLab
pergola list ssh -p pergola-solidtime
# 3. Create the deployment Stage Environment
pergola create stage dev -p pergola-solidtime --type dev --display-name "Development"
```
---
### 2. Stage Configuration & Environment Variables
Configure dynamic and secret variables on the `default` configuration of the `dev` stage. Ensure you replace the placeholders below with your own secure values:
```bash
# Register non-sensitive and sensitive keys (excluding multiline certificates)
pergola add config-data default -p pergola-solidtime -s dev \
  --env APP_KEY="YOUR_BASE64_APP_KEY" \
  --env APP_DOMAIN="https://your-solidtime-domain.pergola.cloud" \
  --env APP_URL="https://your-solidtime-domain.pergola.cloud" \
  --env APP_FORCE_HTTPS="true" \
  --env DB_DATABASE="solidtime" \
  --env DB_USERNAME="solidtime_user" \
  --env DB_PASSWORD="YOUR_STRONG_DATABASE_PASSWORD" \
  --env MAIL_HOST="smtp.mailtrap.io" \
  --env MAIL_PORT="2525" \
  --env MAIL_ENCRYPTION="tls" \
  --env MAIL_FROM_ADDRESS="no-reply@yourdomain.com" \
  --env MAIL_FROM_NAME="Solidtime" \
  --env MAIL_USERNAME="YOUR_SMTP_USERNAME" \
  --env MAIL_PASSWORD="YOUR_SMTP_PASSWORD"
```
#### Binding Passport RSA Cryptographic Keys
Since Laravel Passport requires secure public and private keys to handle OAuth tokens, pass these multiline values carefully using escaped newlines (`\n`):
```bash
# Add multiline Passport Private Key
pergola add config-data default -p pergola-solidtime -s dev \
  --env PASSPORT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_BODY_LINE_1\nYOUR_PRIVATE_KEY_BODY_LINE_2\n...-----END PRIVATE KEY-----"
# Add multiline Passport Public Key
pergola add config-data default -p pergola-solidtime -s dev \
  --env PASSPORT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\nYOUR_PUBLIC_KEY_BODY_LINE_1\nYOUR_PUBLIC_KEY_BODY_LINE_2\n...-----END PUBLIC KEY-----"
```
---
### 3. Build & Release Execution
You can compile a build directly from your repository, or perform a configuration-only release if deploying using direct prebuilt images.
#### Option A: Building from Source Repository
```bash
# 1. Trigger the platform compilation build
pergola push build -p pergola-solidtime --force
# 2. Track the progress of your builds
pergola list build -p pergola-solidtime
# 3. Create a release incorporating the succeeded build and configuration data
pergola push release -p pergola-solidtime -s dev -b master_b1 -c default
```
#### Option B: Configuration-Only Release (Prebuilt Workflow)
Because all services point to pre-built official images in [`pergola.yaml`](pergola.yaml) (`solidtime/solidtime:latest`, `postgres:15`, `gotenberg/gotenberg:8`), you can release using only the stage configuration parameters:
```bash
pergola push release -p pergola-solidtime -s dev -c default
```
Verify that all components start successfully and transition to a `running` state:
```bash
pergola list component -p pergola-solidtime -s dev
```
---
### 4. Database Setup & Administration Command Executions
Once the containers are successfully running, finalize the application initialization inside the `app` container by invoking Artisan commands using `pergola exec`:
```bash
# 1. Run database migrations to provision schemas
pergola exec app -p pergola-solidtime -s dev -- php artisan migrate --force
# 2. Setup internal passport client keys
pergola exec app -p pergola-solidtime -s dev -- php artisan passport:keys --force
# 3. Register your initial Administrator User (interactive prompt)
pergola exec app -p pergola-solidtime -s dev -- php artisan admin:user:create "Your Name" "your-admin-email@domain.com" --verify-email
```
