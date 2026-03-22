FROM node:22-slim

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