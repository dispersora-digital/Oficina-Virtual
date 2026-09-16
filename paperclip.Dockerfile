FROM ghcr.io/paperclipai/paperclip:latest

USER root

# Instalar Python, pip y dependencias de sistema necesarias para ejecutar hermes-agent
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar hermes-agent globalmente en el sistema
RUN pip3 install --no-cache-dir --break-system-packages hermes-agent

USER node
