FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    curl \
    git \
    bash \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalación oficial de Hermes Agent
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

ENV PATH="/root/.local/bin:$PATH"

# Instalación del adaptador oficial para Paperclip
RUN pip3 install --no-cache-dir --break-system-packages hermes-paperclip-adapter || true

WORKDIR /app

# Puerto por defecto para el servicio/adaptador
EXPOSE 8080

# Arranque en loopback o modo servicio sin compuerta de dashboard interactivo
CMD ["hermes", "serve", "--host", "0.0.0.0", "--port", "8080", "--no-auth"]
