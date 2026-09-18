FROM ghcr.io/berriai/litellm:main-latest

WORKDIR /app

COPY litellm-config.yaml /app/config.yaml

EXPOSE 4000

CMD ["--config", "/app/config.yaml", "--port", "4000", "--host", "0.0.0.0"]
