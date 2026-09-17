FROM ghcr.io/paperclipai/paperclip:latest

USER root

# Instalar dependencias esenciales de Python sin sobreescribir librerías del sistema
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar hermes-agent ignorando colisiones con paquetes base del SO
RUN pip3 install --no-cache-dir --break-system-packages --ignore-installed packaging hermes-agent

# Asegurar permisos de ejecución accesibles para el usuario node
RUN which hermes && hermes --version || true

# --- SOLUCIÓN AL ERROR DE PERMISOS EACCES ---
# Crear las carpetas de almacenamiento que usa Hermes y asignar la propiedad al usuario node
RUN mkdir -p /paperclip/instances/default \
    && mkdir -p /paperclip/.hermes \
    && chown -R node:node /paperclip/instances \
    && chown -R node:node /paperclip/.hermes

USER node
