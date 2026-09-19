FROM ghcr.io/berriai/litellm:main-latest

WORKDIR /app

COPY litellm-config.yaml /app/config.yaml
COPY litellm-entrypoint.sh /app/litellm-entrypoint.sh
RUN chmod +x /app/litellm-entrypoint.sh

EXPOSE 4000

ENTRYPOINT ["/app/litellm-entrypoint.sh"]
