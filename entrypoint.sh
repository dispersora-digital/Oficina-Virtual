#!/usr/bin/env bash
set -e

mkdir -p /root/.hermes

cat <<EOF > /root/.hermes/config.yaml
dashboard:
  basic_auth:
    username: "admin"
    password_hash: "pbkdf2:sha256:600000\$xK8jW2\$4c6198f16b23b8fbcad2dc8f4d99c35a8bc3e414163bb4beabf62804b9e4a8dc"

llm:
  provider: "openai"
  model: "gemini-1.5-pro"
  base_url: "http://litellm:4000/v1"
  api_key: "sk-litellm-proxy-internal"
EOF

cat <<EOF > /root/.hermes/.env
OPENAI_API_BASE=http://litellm:4000/v1
OPENAI_API_KEY=sk-litellm-proxy-internal
EOF

exec hermes serve --host 0.0.0.0 --port 8080
