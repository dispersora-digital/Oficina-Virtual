FROM ghcr.io/paperclipai/paperclip:latest

USER root

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages --ignore-installed packaging hermes-agent

RUN which hermes && hermes --version || true

RUN mkdir -p /paperclip/instances/default \
    && mkdir -p /paperclip/.hermes \
    && mkdir -p /home/node/.hermes \
    && chown -R node:node /paperclip/instances \
    && chown -R node:node /paperclip/.hermes \
    && chown -R node:node /home/node/.hermes

# Configurar LiteLLM como proveedor OpenAI predeterminado para Hermes
RUN echo 'OPENAI_API_BASE=http://litellm:4000/v1' >> /etc/environment && \
    echo 'OPENAI_BASE_URL=http://litellm:4000/v1' >> /etc/environment && \
    echo 'OPENAI_API_KEY=sk-litellm-proxy-internal' >> /etc/environment

USER node

# Crear la configuración persistente para el usuario node
RUN mkdir -p ~/.hermes && cat <<EOF > ~/.hermes/config.yaml
llm:
  provider: "openai"
  model: "gemini-1.5-pro"
  base_url: "http://litellm:4000/v1"
  api_key: "sk-litellm-proxy-internal"
EOF
