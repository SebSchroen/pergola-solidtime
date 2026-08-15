# Deployment Plan for Solidtime on Pergola

This playbook contains the exact step-by-step CLI execution sequence to deploy **Solidtime** onto Pergola, using the [`pergola.yaml`](../pergola.yaml) manifest, binding environment variables from [`.env`](../.env) and [`laravel.env`](../laravel.env), running the deployment pipelines, executing migrations, and creating the admin account.

---

## Part 1: Project Provisioning

Since the project does not exist yet under the name `pergola-solidtime` in your projects list, we must create it.

```bash
# 1. Create the Pergola Project
pergola create project pergola-solidtime \
  --git-url git@github.com:SebSchroen/pergola-solidtime.git \
  --display-name "Solidtime Time Tracker"

# 2. Add your SSH keys to GitHub so Pergola can access the repository
pergola list ssh -p pergola-solidtime
```

---

## Part 2: Stage Provisioning

Next, we establish the runtime deployment environment (`dev` stage).

```bash
# Create the development stage environment
pergola create stage dev -p pergola-solidtime --type dev --display-name "Development"
```

---

## Part 3: Environment Variable & Secrets Configuration

Before launching our first release, we populate the default Stage Configuration `default` with the environmental parameters from [`.env`](../.env) and [`laravel.env`](../laravel.env).

```bash
# Add keys to the stage's default configuration
pergola add config-data default -p pergola-solidtime -s dev \
  --env APP_KEY="base64:8K5qDWJ0PfIP1hIwKEWkUAbCOdmIh1qd5iL71/koKXo=" \
  --env APP_DOMAIN="https://solidtime.dev.outpost.pergola.cloud" \
  --env APP_FORCE_HTTPS="false" \
  --env DB_DATABASE="solidtime" \
  --env DB_USERNAME="solidtime" \
  --env DB_PASSWORD="randompassword" \
  --env MAIL_HOST="" \
  --env MAIL_PORT="" \
  --env MAIL_ENCRYPTION="tls" \
  --env MAIL_FROM_ADDRESS="no-reply@your-domain.com" \
  --env MAIL_FROM_NAME="solidtime" \
  --env MAIL_USERNAME="" \
  --env MAIL_PASSWORD=""

# Bind Passport RSA Keys cleanly into config-data entries as they are multiline keys
# We escape the newlines appropriately in the command execution:
pergola add config-data default -p pergola-solidtime -s dev \
  --env PASSPORT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIJQwIBADANBgkqhkiG9w0BAQEFAASCCS0wggkpAgEAAoICAQDUTPH7i2hgBcvg\n/DOakjyqcr/vhKV662o0caJJ2BDvmSq6L2HzwLwQsEsR9uu8Fa6JZ36LE9FE0MB7\nkdF0n7Sy3nIaJadj6ozABFH5x+Iq0YFtA9fskKoVo6nkx6ak/yVHuOu+j2RlaViF\naHs0srtANbzmBJXU93WxPxb5c4i5s8Bdq1CYiicPHRRqqV+L5404+RujoKcuEMS/\nRIXw0fMMBoDL9zhNxsPu27bwcZ4eJwLaa0u7Vl+l3XHaAWcy33Q8rkqnWUZNZoIE\nsS6BneIsK4yfH7NyGaOK8gjyQYbJvD+Y3ZYvZYEasnHfVtxnIQfbam47ndc3AuSr\nf3c3QeVr6bJW7MFxmoLSvl46dCVzeKMN1XWXT+N05boYnmqXRMW6lg226Fk+tdYj\niZ8JGhUOda18hFI72Pp6yMV4ANBinh0eo0R2Wy0wZ6VsMxYoUUSm5790F8/E9FGZ\n0lC+gJ3RlOUbqmMB6Lu1X6+rqNVDUgbol1Za/48y5qTfit7hfG7DcS5qRIt2WRmd\nQdGRdSZkJT9+bBgehNcQXZ/jcQYt2GQ5s3fO0nmoaLosOswxE33ObKrPy/bubrQy\nXeG85qBWhUPSkObOSHg+AQyJBPml/d3yimNfw/LohY3B4IZ/zagU8MesQl5SpA0U\n9j4C2kIdOctlgcWaLrKQyljP/1WokQIDAQABAoICABeXR0p29s24xyuEiu1xs5kT\nMD3a5RKQJ1iVif2fq14cjJFs43sVHzDRjj38TLy1QhRVskudE6OMeN8iWH6Xopo/\nurkqFvw025gYws05R2oPpsyo4S0R9Dx8V8wq3Vs3WPqr01J1F6hnOOV2Mz6rX8Bm\nWEvNFaM5LlRYWOK2UmqkTUt7VnTk4Ss+RX8GvC3NOLWshMQ9fWZSibJhWGrmwZXE\nATrpCVInNK2Nr7nvPi1Gk3wW8S7rjaxeO6EIh+Gwz/dQPM50zqmaKvd/gtX3Z+MV\nocYq3SNgMvqlI5Zb7rDrILwJX397zYlca+fv/ITfOELLBF3Oj9Q2l5dxDhvPUEFm\nOgyJdcbhdw7ESeM11he7goyWYhiLtNs238htrd5JQGJLcEDNAlNK0gqy4gMlrRE0\nc7TXwXJZgOgNsigNCdq2Dluoh/zwn5oMl5kDQLdXCM8wT/jmNp1lgUSNdHk4/BDf\nUMOYHfQeZ1u8bwTj4zZN2tr5YJN/MwEqIYn4/curAA0c7dgWoX5Mr0NJyqKKEFNw\nY+zrAphAVVhTTe7UAYg621UK9Fu7mGW8vMYFvk9oXrU4MjZd22s3KHvXhFpOr3Zj\njZlJHUiCXjdgLl0wX5dioxzZNJLYPcRgXBFdGTHN7MyW+tNrBv+Nn/EmtxG5y4BG\nuSMnj1scqrjKqdIALHWZAoIBAQDxiyFqghQ6+GSZQAf3wMiK2lfe69YlQVvVLnrr\ne91OkDzN+vqyr3v5ySmeIOm4UrzWGEjYeZvUig9GiP0/U7TASFg8k9sVchHDFd9a\noghR/MKQ0nUEtg6hrFUJURsSp/Lggj5rUfIBnYQ+eccb0qh6uZ77ee60zqidZif3\nfXGguRuSgGnTKstddWvtLFcRzzxCeebay/piNnCSWCrR5fahnbjSXF3bj63p/UC3\n7JqlCZ0cpJ8dPBn3RdXfIoPbvRAlyrAcIcXgfEjclSqXpSzdzgmzLH+aWPXRDA+C\nN9qDMZ+uvovSsp7LpU3VoQO99iOyfFQNE3e5F/ToPWOeKy39AoIBAQDhAcMWEklz\nXnssq53npreiCZlwXwLkPkRP34hYUNtISOBfqvSw3n8u9A1hLTwqVUv2jcq02kqH\nDsx5WlDGzGWYeOnNyavlTjFa1xmVucJk...\n-----END PRIVATE KEY-----" \
  --env PASSPORT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\nMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1Ezx+4toYAXL4PwzmpI8\nqnK/74SleutqNHGiSdgQ75kqui9h88C8ELBLEfbrvBWuiWd+ixPRRNDAe5HRdJ+0\nst5yGiWnY+qMwARR+cfiKtGBbQPX7JCqFaOp5MempP8lR7jrvo9kZWlYhWh7NLK7\nQDW85gSV1Pd1sT8W+XOIubPAXatQmIonDx0Uaqlfi+eNOPkbo6CnLhDEv0SF8NHz\nDAaAy/c4TcbD7tu28HGeHicC2mtLu1Zfpd1x2gFnMt90PK5Kp1lGTWaCBLEugZ3i\nLCuMnx+zchmjivII8kGGybw/mN2WL2WBGrJx31bcZyEH22puO53XNwLkq393N0Hl\na+myVuzBcZqC0r5eOnQlc3ijDdV1l0/jdOW6GJ5ql0TFupYNtuhZPrXWI4mfCRoV\nDnWtfIRSO9j6esjFeADQYp4dHqNEdlstMGelbDMWKFFEpue/dBfPxPRRmdJQvoCd\n0ZTlG6pjAei7tV+vq6jVQ1IG6JdWWv+PMuak34re4Xxuw3EuakSLdlkZnUHRkXUm\nZCU/fmwYHoTXEF2f43EGLdhkObN3ztJ5qGi6LDrMMRN9zmyqz8v27m60Ml3hvOag\nVoVD0pDmzkh4PgEMiQT5pf3d8opjX8Py6IWNweCGf82oFPDHrEJeUqQNFPY+AtpC\nHTnLZYHFmi6ykMpYz/9VqJECAwEAAQ==\n-----END PUBLIC KEY-----"
```

---

## Part 4: Building & Releasing

Now we trigger a platform build and deploy it onto the stage environment once the build pipeline reports success.

```bash
# 1. Trigger the Project Build
# (Your repo must contain pergola.yaml in its default branch or the targeted branch)
pergola push build -p pergola-solidtime --force

# 2. Track the progress of the build
pergola list build -p pergola-solidtime

# 3. Deploy the succeeded build (e.g. master_b1) and our configuration parameters
# Replace 'master_b1' with the actual build name obtained from the previous step
pergola push release -p pergola-solidtime -s dev -b master_b1 -c default

# 4. Monitor deployed components status
pergola list component -p pergola-solidtime -s dev
```

---

## Part 5: Database Provisioning & Application Setup

Once the components are active and reporting `running`, we run the database migrations and setup task commands using the `pergola exec` feature.

### 1. Run Database Migrations
Run the Laravel schema migration command in the `app` container. This will connect to the `database` component and provision the schema.

```bash
pergola exec app -p pergola-solidtime -s dev -- php artisan migrate --force
```

### 2. Generate Passport Client Keys
Initialize passport oauth client keys so authentication flows work correctly:

```bash
pergola exec app -p pergola-solidtime -s dev -- php artisan passport:keys --force
```

### 3. Create the Admin User Account
Solidtime provides a Laravel console helper command to register the initial administrator:

```bash
# This starts an interactive command where you can safely enter your admin email and password.
# 'pergola exec' natively supports interactive stdin/stdout streams.
pergola exec app -p pergola-solidtime -s dev -- php artisan admin:user:create "Sebastian Schroen" "pergola@finconda.de" --verify-email


```
