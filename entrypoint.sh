#!/usr/bin/env bash
set -euo pipefail

mkdir -p /root/.hermes

LITELLM_BASE_URL="${LITELLM_BASE_URL:-http://litellm:4000/v1}"
LITELLM_KEY="${OPENAI_API_KEY:-${LITELLM_MASTER_KEY:-sk-litellm-proxy-internal}}"
DEFAULT_MODEL="${DEFAULT_MODEL:-gemini-flash}"
PORT="${PORT:-8080}"

# Config moderna de Hermes: LiteLLM como provider custom, Gemini detrás.
cat > /root/.hermes/config.yaml <<EOF
model:
  provider: custom
  default: ${DEFAULT_MODEL}
  base_url: ${LITELLM_BASE_URL}
  api_mode: chat_completions

providers:
  litellm:
    api: ${LITELLM_BASE_URL}
    discover_models: true

agent:
  max_turns: 90

tool_loop_guardrails:
  non_interactive_hard_stop_enabled: false
EOF

cat > /root/.hermes/.env <<EOF
OPENAI_API_BASE=${LITELLM_BASE_URL}
OPENAI_BASE_URL=${LITELLM_BASE_URL}
OPENAI_API_KEY=${LITELLM_KEY}
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=${PORT}
API_SERVER_KEY=${API_SERVER_KEY:-${LITELLM_KEY}}
EOF

export PATH="/root/.local/bin:${PATH}"
export API_SERVER_ENABLED=true
export API_SERVER_HOST=0.0.0.0
export API_SERVER_PORT="${PORT}"
export API_SERVER_KEY="${API_SERVER_KEY:-${LITELLM_KEY}}"
export OPENAI_API_BASE="${LITELLM_BASE_URL}"
export OPENAI_BASE_URL="${LITELLM_BASE_URL}"
export OPENAI_API_KEY="${LITELLM_KEY}"

if command -v hermes >/dev/null 2>&1; then
  if hermes gateway run --help >/dev/null 2>&1; then
    exec hermes gateway run
  fi
  if hermes serve --help >/dev/null 2>&1; then
    exec hermes serve --host 0.0.0.0 --port "${PORT}"
  fi
  exec hermes gateway
fi

echo "hermes no está en PATH" >&2
exit 1
