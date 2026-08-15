# Pergola Migration Plan: Solidtime Application Stack

This document details the architectural plan to migrate the [`docker-compose.yml`](docker-compose.yml) stack to a native Pergola manifest ([`pergola.yaml`](pergola.yaml)), utilizing stage-specific configurations via `config-ref`, proper component linking, and persistent storage definitions.

---

## 1. Architectural Overview & Component Mapping

We map the services from [`docker-compose.yml`](docker-compose.yml) to Pergola components as follows:

| Docker Compose Service | Pergola Component | Component Type / Nature | Storage / Volumes | Public Exposure (Ingress) |
| :--- | :--- | :--- | :--- | :--- |
| `app` | `app` | Web service (HTTP engine) | `app-storage` (2Gi at `/var/www/html/storage`) | Exposed publicly on host `solidtime` |
| `scheduler` | `scheduler` | Scheduled cron worker | `scheduler-storage` (2Gi at `/var/www/html/storage`) | Internal only |
| `queue` | `queue` | Background queue consumer | `queue-storage` (2Gi at `/var/www/html/storage`) | Internal only |
| `database` | `database` | Database backend (`postgres:15`) | `database-storage` (5Gi at `/var/lib/postgresql/data`) | Internal only |
| `gotenberg` | `gotenberg` | PDF generation service | None (stateless) | Internal only |

---

## 2. Environment Variables & Secret Configuration

To keep the manifest clean and reusable across different stages (dev, qa, prod), we split configuration between:
1. **Static environment variables** specified directly in [`pergola.yaml`](pergola.yaml).
2. **Dynamic/Sensitive values** loaded via `config-ref` referencing Pergola Stage `config-data`.

### Mapping Analysis

#### Static Variables (defined in [`pergola.yaml`](pergola.yaml))
- `CONTAINER_MODE` (unique per component: `http` for `app`, `worker` for `queue`, `scheduler` for `scheduler`)
- `WORKER_COMMAND` (`"php /var/www/html/artisan queue:work"` for `queue`)
- `APP_ENV` (`production`)
- `APP_DEBUG` (`false`)
- `TRUSTED_PROXIES` (`"0.0.0.0/0,2000:0:0:0:0:0:0:0/3"`)
- `LOG_CHANNEL` (`"stderr_daily"`)
- `LOG_LEVEL` (`"debug"`)
- `DB_CONNECTION` (`"pgsql"`)
- `DB_PORT` (`5432`)
- `DB_SSLMODE` (`"prefer"`) (Note: PostgreSQL runs internally inside the cluster, so local connections are secured)
- `QUEUE_CONNECTION` (`"database"`)
- `FILESYSTEM_DISK` (`"local"`)
- `PUBLIC_FILESYSTEM_DISK` (`"public"`)
- `GOTENBERG_URL` (`"http://gotenberg:3000"`)

#### Dynamic/Sensitive Variables (mapped via `config-ref`)
- `APP_KEY`
- `APP_DOMAIN`
- `APP_FORCE_HTTPS`
- `PASSPORT_PRIVATE_KEY`
- `PASSPORT_PUBLIC_KEY`
- `DB_DATABASE`
- `DB_USERNAME`
- `DB_PASSWORD`
- `MAIL_HOST`
- `MAIL_PORT`
- `MAIL_ENCRYPTION`
- `MAIL_FROM_ADDRESS`
- `MAIL_FROM_NAME`
- `MAIL_USERNAME`
- `MAIL_PASSWORD`

---

## 3. Network Architecture & Service Discovery (Component Linking)

Internal communication is decoupled and utilizes internal DNS provided automatically by Pergola:
- **Database Access:** `DB_HOST` in the `app`, `scheduler`, and `queue` components is bound via `component-ref: database`.
- **Gotenberg Access:** `GOTENBERG_URL` points directly to `http://gotenberg:3000` internally.

---

## 4. Proposed [`pergola.yaml`](pergola.yaml)

```yaml
version: v1
components:
  - name: app
    docker:
      image: solidtime/solidtime:latest
    ports:
      - 8000
    ingresses:
      - host: solidtime
        port: 8000
    storage:
      - name: app-storage
        path: /var/www/html/storage
        size: 2Gi
    env:
      - name: CONTAINER_MODE
        value: http
      - name: APP_NAME
        value: solidtime
      - name: VITE_APP_NAME
        value: solidtime
      - name: APP_ENV
        value: production
      - name: APP_DEBUG
        value: "false"
      - name: TRUSTED_PROXIES
        value: "0.0.0.0/0,2000:0:0:0:0:0:0:0/3"
      - name: LOG_CHANNEL
        value: stderr_daily
      - name: LOG_LEVEL
        value: debug
      - name: DB_CONNECTION
        value: pgsql
      - name: DB_HOST
        component-ref: database
      - name: DB_PORT
        value: "5432"
      - name: DB_SSLMODE
        value: prefer
      - name: QUEUE_CONNECTION
        value: database
      - name: FILESYSTEM_DISK
        value: local
      - name: PUBLIC_FILESYSTEM_DISK
        value: public
      - name: GOTENBERG_URL
        value: "http://gotenberg:3000"
      - name: APP_KEY
        config-ref: APP_KEY
      - name: APP_DOMAIN
        config-ref: APP_DOMAIN
      - name: APP_FORCE_HTTPS
        config-ref: APP_FORCE_HTTPS
      - name: PASSPORT_PRIVATE_KEY
        config-ref: PASSPORT_PRIVATE_KEY
      - name: PASSPORT_PUBLIC_KEY
        config-ref: PASSPORT_PUBLIC_KEY
      - name: DB_DATABASE
        config-ref: DB_DATABASE
      - name: DB_USERNAME
        config-ref: DB_USERNAME
      - name: DB_PASSWORD
        config-ref: DB_PASSWORD
      - name: MAIL_HOST
        config-ref: MAIL_HOST
      - name: MAIL_PORT
        config-ref: MAIL_PORT
      - name: MAIL_ENCRYPTION
        config-ref: MAIL_ENCRYPTION
      - name: MAIL_FROM_ADDRESS
        config-ref: MAIL_FROM_ADDRESS
      - name: MAIL_FROM_NAME
        config-ref: MAIL_FROM_NAME
      - name: MAIL_USERNAME
        config-ref: MAIL_USERNAME
      - name: MAIL_PASSWORD
        config-ref: MAIL_PASSWORD

  - name: scheduler
    docker:
      image: solidtime/solidtime:latest
    # Run the scheduler as a cron job executing every minute
    scheduled: "* * * * *"
    command:
      - php
      - /var/www/html/artisan
      - schedule:run
    storage:
      - name: scheduler-storage
        path: /var/www/html/storage
        size: 2Gi
    env:
      - name: CONTAINER_MODE
        value: scheduler
      - name: APP_NAME
        value: solidtime
      - name: VITE_APP_NAME
        value: solidtime
      - name: APP_ENV
        value: production
      - name: APP_DEBUG
        value: "false"
      - name: TRUSTED_PROXIES
        value: "0.0.0.0/0,2000:0:0:0:0:0:0:0/3"
      - name: LOG_CHANNEL
        value: stderr_daily
      - name: LOG_LEVEL
        value: debug
      - name: DB_CONNECTION
        value: pgsql
      - name: DB_HOST
        component-ref: database
      - name: DB_PORT
        value: "5432"
      - name: DB_SSLMODE
        value: prefer
      - name: QUEUE_CONNECTION
        value: database
      - name: FILESYSTEM_DISK
        value: local
      - name: PUBLIC_FILESYSTEM_DISK
        value: public
      - name: GOTENBERG_URL
        value: "http://gotenberg:3000"
      - name: APP_KEY
        config-ref: APP_KEY
      - name: APP_DOMAIN
        config-ref: APP_DOMAIN
      - name: APP_FORCE_HTTPS
        config-ref: APP_FORCE_HTTPS
      - name: PASSPORT_PRIVATE_KEY
        config-ref: PASSPORT_PRIVATE_KEY
      - name: PASSPORT_PUBLIC_KEY
        config-ref: PASSPORT_PUBLIC_KEY
      - name: DB_DATABASE
        config-ref: DB_DATABASE
      - name: DB_USERNAME
        config-ref: DB_USERNAME
      - name: DB_PASSWORD
        config-ref: DB_PASSWORD
      - name: MAIL_HOST
        config-ref: MAIL_HOST
      - name: MAIL_PORT
        config-ref: MAIL_PORT
      - name: MAIL_ENCRYPTION
        config-ref: MAIL_ENCRYPTION
      - name: MAIL_FROM_ADDRESS
        config-ref: MAIL_FROM_ADDRESS
      - name: MAIL_FROM_NAME
        config-ref: MAIL_FROM_NAME
      - name: MAIL_USERNAME
        config-ref: MAIL_USERNAME
      - name: MAIL_PASSWORD
        config-ref: MAIL_PASSWORD

  - name: queue
    docker:
      image: solidtime/solidtime:latest
    storage:
      - name: queue-storage
        path: /var/www/html/storage
        size: 2Gi
    env:
      - name: CONTAINER_MODE
        value: worker
      - name: WORKER_COMMAND
        value: "php /var/www/html/artisan queue:work"
      - name: APP_NAME
        value: solidtime
      - name: VITE_APP_NAME
        value: solidtime
      - name: APP_ENV
        value: production
      - name: APP_DEBUG
        value: "false"
      - name: TRUSTED_PROXIES
        value: "0.0.0.0/0,2000:0:0:0:0:0:0:0/3"
      - name: LOG_CHANNEL
        value: stderr_daily
      - name: LOG_LEVEL
        value: debug
      - name: DB_CONNECTION
        value: pgsql
      - name: DB_HOST
        component-ref: database
      - name: DB_PORT
        value: "5432"
      - name: DB_SSLMODE
        value: prefer
      - name: QUEUE_CONNECTION
        value: database
      - name: FILESYSTEM_DISK
        value: local
      - name: PUBLIC_FILESYSTEM_DISK
        value: public
      - name: GOTENBERG_URL
        value: "http://gotenberg:3000"
      - name: APP_KEY
        config-ref: APP_KEY
      - name: APP_DOMAIN
        config-ref: APP_DOMAIN
      - name: APP_FORCE_HTTPS
        config-ref: APP_FORCE_HTTPS
      - name: PASSPORT_PRIVATE_KEY
        config-ref: PASSPORT_PRIVATE_KEY
      - name: PASSPORT_PUBLIC_KEY
        config-ref: PASSPORT_PUBLIC_KEY
      - name: DB_DATABASE
        config-ref: DB_DATABASE
      - name: DB_USERNAME
        config-ref: DB_USERNAME
      - name: DB_PASSWORD
        config-ref: DB_PASSWORD
      - name: MAIL_HOST
        config-ref: MAIL_HOST
      - name: MAIL_PORT
        config-ref: MAIL_PORT
      - name: MAIL_ENCRYPTION
        config-ref: MAIL_ENCRYPTION
      - name: MAIL_FROM_ADDRESS
        config-ref: MAIL_FROM_ADDRESS
      - name: MAIL_FROM_NAME
        config-ref: MAIL_FROM_NAME
      - name: MAIL_USERNAME
        config-ref: MAIL_USERNAME
      - name: MAIL_PASSWORD
        config-ref: MAIL_PASSWORD

  - name: database
    docker:
      image: postgres:15
    ports:
      - 5432
    storage:
      - name: database-storage
        path: /var/lib/postgresql/data
        size: 5Gi
    env:
      - name: PGPASSWORD
        config-ref: DB_PASSWORD
      - name: POSTGRES_DB
        config-ref: DB_DATABASE
      - name: POSTGRES_USER
        config-ref: DB_USERNAME
      - name: POSTGRES_PASSWORD
        config-ref: DB_PASSWORD

  - name: gotenberg
    docker:
      image: gotenberg/gotenberg:8
    ports:
      - 3000
```

---

## 5. Migration Playbook & Command Reference

To initialize the stage configuration parameters with keys extracted from the environment files, run the following commands:

```bash
# Initialize and apply the config data dynamically
pergola set config-data -c default --key APP_KEY --value "base64:8K5qDWJ0PfIP1hIwKEWkUAbCOdmIh1qd5iL71/koKXo="
pergola set config-data -c default --key APP_DOMAIN --value "https://solidtime.stage.outpost.pergola.cloud"
pergola set config-data -c default --key APP_FORCE_HTTPS --value "true"
pergola set config-data -c default --key DB_DATABASE --value "solidtime"
pergola set config-data -c default --key DB_USERNAME --value "solidtime"
pergola set config-data -c default --key DB_PASSWORD --value "randompassword"
# Apply PASSPORT keys (from laravel.env) similarly...
```
