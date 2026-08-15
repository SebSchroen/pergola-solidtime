# Deployment Plan for Solidtime on Pergola (No Repository Flow)

If you don't have a remote Git repository hosted on GitHub or GitLab yet, Pergola cannot clone and build the code automatically. 

Below are the two recommended pathways to initialize your project: **Option A (Initialize a new remote Git Repository)** or **Option B (Temporary Local/Prebuilt workflow)**.

---

## Option A: Recommended — Initialize Remote GitHub Repository

Pergola's deployment architecture relies on Git-driven build triggers. Setting up a remote git repository takes less than a minute.

```bash
# 1. Initialize Git locally (if not already done)
git init
git add .
git commit -m "feat: migrate to pergola"

# 2. Create a new repository on your GitHub account (using GitHub CLI 'gh' or web UI)
gh repo create pergola-solidtime --private --source=. --remote=origin --push

# 3. Create the Pergola Project referencing your new repository
pergola create project pergola-solidtime \
  --git-url git@github.com:your-github-username/pergola-solidtime.git \
  --display-name "Solidtime Time Tracker"

# 4. Generate the Deploy SSH Key for GitHub and add it to your repo's Deploy Keys
pergola create ssh -p pergola-solidtime
```

---

## Option B: Deploy Prebuilt Images Directly (No Custom Code Build Needed)

Since Solidtime uses official upstream Docker images (`solidtime/solidtime:${SOLIDTIME_IMAGE_TAG:-latest}`) rather than compiling custom codebase changes, you can use Pergola to deploy directly from the public registry without configuring any private Git repositories or write-access tokens.

You can link a dummy/empty repository or any public placeholder repository just to establish the project container.

### Step 1: Initialize the Project Container
Establish a project targeting any public placeholder git repository (since our manifest specifies prebuilt docker images, we don't compile code from the repo):

```bash
pergola create project pergola-solidtime \
  --git-url https://github.com/SebSchroen/pergola-solidtime.git \
  --display-name "Solidtime Time Tracker"
```

### Step 2: Provision Stage & Add Configuration
Create the stage and populate the config-data keys extracted from your env files.

```bash
# Create stage
pergola create stage dev -p pergola-solidtime --type dev --display-name "Development"

# Configure Stage Secrets & Parameters
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

# Multiline private key bindings
pergola add config-data default -p pergola-solidtime -s dev \
  --env PASSPORT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIJQwIBADANBgkqhkiG9w0BAQEFAASCCS0wggkpAgEAAoICAQDUTPH7i2hgBcvg\n/DOakjyqcr/vhKV662o0caJJ2BDvmSq6L2HzwLwQsEsR9uu8Fa6JZ36LE9FE0MB7\nkdF0n7Sy3nIaJadj6ozABFH5x+Iq0YFtA9fskKoVo6nkx6ak/yVHuOu+j2RlaViF\naHs0srtANbzmBJXU93WxPxb5c4i5s8Bdq1CYiicPHRRqqV+L5404+RujoKcuEMS/\nRIXw0fMMBoDL9zhNxsPu27bwcZ4eJwLaa0u7Vl+l3XHaAWcy33Q8rkqnWUZNZoIE\nsS6BneIsK4yfH7NyGaOK8gjyQYbJvD+Y3ZYvZYEasnHfVtxnIQfbam47ndc3AuSr\nf3c3QeVr6bJW7MFxmoLSvl46dCVzeKMN1XWXT+N05boYnmqXRMW6lg226Fk+tdYj\niZ8JGhUOda18hFI72Pp6yMV4ANBinh0eo0R2Wy0wZ6VsMxYoUUSm5790F8/E9FGZ\n0lC+gJ3RlOUbqmMB6Lu1X6+rqNVDUgbol1Za/48y5qTfit7hfG7DcS5qRIt2WRmd\nQdGRdSZkJT9+bBgehNcQXZ/jcQYt2GQ5s3fO0nmoaLosOswxE33ObKrPy/bubrQy\nXeG85qBWhUPSkObOSHg+AQyJBPml/d3yimNfw/LohY3B4IZ/zagU8MesQl5SpA0U\n9j4C2kIdOctlgcWaLrKQyljP/1WokQIDAQABAoICABeXR0p29s24xyuEiu1xs5kT\nMD3a5RKQJ1iVif2fq14cjJFs43sVHzDRjj38TLy1QhRVskudE6OMeN8iWH6Xopo/\nurkqFvw025gYws05R2oPpsyo4S0R9Dx8V8wq3Vs3WPqr01J1F6hnOOV2Mz6rX8Bm\nWEvNFaM5LlRYWOK2UmqkTUt7VnTk4Ss+RX8GvC3NOLWshMQ9fWZSibJhWGrmwZXE\nATrpCVInNK2Nr7nvPi1Gk3wW8S7rjaxeO6EIh+Gwz/dQPM50zqmaKvd/gtX3Z+MV\nocYq3SNgMvqlI5Zb7rDrILwJX397zYlca+fv/ITfOELLBF3Oj9Q2l5dxDhvPUEFm\nOgyJdcbhdw7ESeM11he7goyWYhiLtNs238htrd5JQGJLcEDNAlNK0gqy4gMlrRE0\nc7TXwXJZgOgNsigNCdq2Dluoh/zwn5oMl5kDQLdXCM8wT/jmNp1lgUSNdHk4/BDf\nUMOYHfQeZ1u8bwTj4zZN2tr5YJN/MwEqIYn4/curAA0c7dgWoX5Mr0NJyqKKEFNw\nY+zrAphAVVhTTe7UAYg621UK9Fu7mGW8vMYFvk9oXrU4MjZd22s3KHvXhFpOr3Zj\njZlJHUiCXjdgLl0wX5dioxzZNJLYPcRgXBFdGTHN7MyW+tNrBv+Nn/EmtxG5y4BG\nuSMnj1scqrjKqdIALHWZAoIBAQDxiyFqghQ6+GSZQAf3wMiK2lfe69YlQVvVLnrr\ne91OkDzN+vqyr3v5ySmeIOm4UrzWGEjYeZvUig9GiP0/U7TASFg8k9sVchHDFd9a\noghR/MKQ0nUEtg6hrFUJURsSp/Lggj5rUfIBnYQ+eccb0qh6uZ77ee60zqidZif3\nfXGguRuSgGnTKstddWvtLFcRzzxCeebay/piNnCSWCrR5fahnbjSXF3bj63p/UC3\n7JqlCZ0cpJ8dPBn3RdXfIoPbvRAlyrAcIcXgfEjclSqXpSzdzgmzLH+aWPXRDA+C\nN9qDMZ+uvovSsp7LpU3VoQO99iOyfFQNE3e5F/ToPWOeKy39AoIBAQDhAcMWEklz\nXnssq53npreiCZlwXwLkPkRP34hYUNtISOBfqvSw3n8u9A1hLTwqVUv2jcq02kqH\nDsx5WlDGzGWYeOnNyavlTjFa1xmVucJk...\n-----END PRIVATE KEY-----" \
  --env PASSPORT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\nMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA1Ezx+4toYAXL4PwzmpI8\nqnK/74SleutqNHGiSdgQ75kqui9h88C8ELBLEfbrvBWuiWd+ixPRRNDAe5HRdJ+0\nst5yGiWnY+qMwARR+cfiKtGBbQPX7JCqFaOp5MempP8lR7jrvo9kZWlYhWh7NLK7\nQDW85gSV1Pd1sT8W+XOIubPAXatQmIonDx0Uaqlfi+eNOPkbo6CnLhDEv0SF8NHz\nDAaAy/c4TcbD7tu28HGeHicC2mtLu1Zfpd1x2gFnMt90PK5Kp1lGTWaCBLEugZ3i\nLCuMnx+zchmjivII8kGGybw/mN2WL2WBGrJx31bcZyEH22puO53XNwLkq393N0Hl\na+myVuzBcZqC0r5eOnQlc3ijDdV1l0/jdOW6GJ5ql0TFupYNtuhZPrXWI4mfCRoV\nDnWtfIRSO9j6esjFeADQYp4dHqNEdlstMGelbDMWKFFEpue/dBfPxPRRmdJQvoCd\n0ZTlG6pjAei7tV+vq6jVQ1IG6JdWWv+PMuak34re4Xxuw3EuakSLdlkZnUHRkXUm\nZCU/fmwYHoTXEF2f43EGLdhkObN3ztJ5qGi6LDrMMRN9zmyqz8v27m60Ml3hvOag\nVoVD0pDmzkh4PgEMiQT5pf3d8opjX8Py6IWNweCGf82oFPDHrEJeUqQNFPY+AtpC\nHTnLZYHFmi6ykMpYz/9VqJECAwEAAQ==\n-----END PUBLIC KEY-----"
```

### Step 3: Trigger Config-Only Release
Because all components utilize public images defined statically inside [`pergola.yaml`](../pergola.yaml) (`solidtime/solidtime:latest`, `postgres:15`, `gotenberg/gotenberg:8`), you can perform a config-only release, which tells Pergola to pull those exact images directly:

```bash
# Push release deploying only config (this fetches & starts the images declared in pergola.yaml)
pergola push release -p pergola-solidtime -s dev -c default
```
