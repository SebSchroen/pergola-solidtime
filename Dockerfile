# Use the latest stable Debian slim image as the base
FROM debian:bookworm-slim

# Set environment variables for non-interactive apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Update apt-get, install curl and ca-certificates, and clean up apt cache
# --no-install-recommends is used to minimize installed packages.
# ca-certificates is crucial for curl to work with HTTPS.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the PATH environment variable for the pergo.a CLI
ENV PATH="/root/.local/bin:$PATH"

# Download and install the pergola CLI
RUN curl -fsSL https://get.pergo.la/cli/latest/install.sh | bash