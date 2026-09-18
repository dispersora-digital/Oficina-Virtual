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

RUN mkdir -p /paperclip/instances/default \
    && mkdir -p /paperclip/.hermes \
    && mkdir -p /home/node/.hermes \
    && mkdir -p /root/.hermes \
    && chown -R node:node /paperclip/instances \
    && chown -R node:node /paperclip/.hermes \
    && chown -R node:node /home/node/.hermes

# Crear configuraciones globales para root y node (sin forzar provider)
RUN printf 'model: "gemini-1.5-pro"\nbase_url: "http://litellm:4000/v1"\napi_key: "sk-litellm-proxy-internal"\n' > /root/.hermes/config.yaml && \
    printf 'model: "gemini-1.5-pro"\nbase_url: "http://litellm:4000/v1"\napi_key: "sk-litellm-proxy-internal"\n' > /home/node/.hermes/config.yaml && \
    chown node:node /home/node/.hermes/config.yaml

ENV OPENAI_API_BASE=http://litellm:4000/v1
ENV OPENAI_BASE_URL=http://litellm:4000/v1
ENV OPENAI_API_KEY=sk-litellm-proxy-internal

USER node
