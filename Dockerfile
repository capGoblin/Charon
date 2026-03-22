FROM node:22-slim

# EigenCompute required labels
LABEL eigenx_cli_version="0.1.0"
LABEL eigenx_use_ita="True"
LABEL tee.launch_policy.log_redirect="always"
LABEL tee.launch_policy.monitoring_memory_allow="always"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    bash \
    git \
    uuid-runtime \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install OpenClaw
RUN npm install -g openclaw@latest

# Copy himalaya binary directly — exact version from your machine
COPY himalaya /usr/local/bin/himalaya
RUN chmod +x /usr/local/bin/himalaya

# Copy entire .openclaw folder
COPY .openclaw/ /root/.openclaw/

# Copy himalaya config
COPY himalaya-config.toml /root/.config/himalaya/config.toml

# Create himalaya downloads dir
RUN mkdir -p /root/downloads

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]