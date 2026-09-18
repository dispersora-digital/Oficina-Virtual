FROM ghcr.io/paperclipai/paperclip:latest

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages --ignore-installed packaging hermes-agent \
    || pip3 install --no-cache-dir --break-system-packages hermes-agent

RUN mkdir -p /paperclip/instances/default \
    /paperclip/.hermes \
    /home/node/.hermes \
    /root/.hermes \
    && chown -R node:node /paperclip /home/node/.hermes

# Hermes dentro de Paperclip también sale por LiteLLM → Gemini.
# El provider es custom (OpenAI-compatible), no el nativo gemini.
RUN printf '%s\n' \
    'model:' \
    '  provider: custom' \
    '  default: gemini-flash' \
    '  base_url: http://litellm:4000/v1' \
    '  api_mode: chat_completions' \
    > /root/.hermes/config.yaml \
    && cp /root/.hermes/config.yaml /home/node/.hermes/config.yaml \
    && chown node:node /home/node/.hermes/config.yaml

ENV HOST=0.0.0.0
ENV PORT=3100
ENV OPENAI_API_BASE=http://litellm:4000/v1
ENV OPENAI_BASE_URL=http://litellm:4000/v1

USER node
