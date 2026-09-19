FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PATH="/root/.local/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    bash \
    python3 \
    python3-pip \
    ca-certificates \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh
COPY paperclip-done.sh /app/paperclip-done.sh
RUN chmod +x /app/entrypoint.sh /app/paperclip-done.sh \
    && ln -sf /app/paperclip-done.sh /usr/local/bin/paperclip-done

EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]
