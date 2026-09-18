# Crear configuraciones globales para root y node (sin forzar provider)
RUN printf 'model: "gemini-1.5-pro"\nbase_url: "http://litellm:4000/v1"\napi_key: "sk-litellm-proxy-internal"\n' > /root/.hermes/config.yaml && \
    printf 'model: "gemini-1.5-pro"\nbase_url: "http://litellm:4000/v1"\napi_key: "sk-litellm-proxy-internal"\n' > /home/node/.hermes/config.yaml && \
    chown node:node /home/node/.hermes/config.yaml

ENV OPENAI_API_BASE=http://litellm:4000/v1
ENV OPENAI_BASE_URL=http://litellm:4000/v1
ENV OPENAI_API_KEY=sk-litellm-proxy-internal
