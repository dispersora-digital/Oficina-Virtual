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
  max_turns: 12
  disabled_toolsets:
    - code_execution

platform_toolsets:
  api_server:
    - web
    - file
    - memory
    - terminal

approvals:
  mode: smart
  unattended_mode: deny

command_allowlist:
  - paperclip-done
  - /usr/local/bin/paperclip-done
  - /app/paperclip-done.sh

tool_loop_guardrails:
  non_interactive_hard_stop_enabled: true
EOF

cat > /root/.hermes/.env <<EOF
OPENAI_API_BASE=${LITELLM_BASE_URL}
OPENAI_BASE_URL=${LITELLM_BASE_URL}
OPENAI_API_KEY=${LITELLM_KEY}
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=${PORT}
API_SERVER_KEY=${API_SERVER_KEY:-${LITELLM_KEY}}
PAPERCLIP_API_URL=${PAPERCLIP_API_URL:-http://paperclip:3100}
PAPERCLIP_URL=${PAPERCLIP_URL:-http://paperclip:3100}
PAPERCLIP_API_KEY=${PAPERCLIP_API_KEY:-}
PAPERCLIP_AGENT_ID=${PAPERCLIP_AGENT_ID:-}
PAPERCLIP_COMPANY_ID=${PAPERCLIP_COMPANY_ID:-}
EOF

export PATH="/root/.local/bin:${PATH}"
export API_SERVER_ENABLED=true
export API_SERVER_HOST=0.0.0.0
export API_SERVER_PORT="${PORT}"
export API_SERVER_KEY="${API_SERVER_KEY:-${LITELLM_KEY}}"
export OPENAI_API_BASE="${LITELLM_BASE_URL}"
export OPENAI_BASE_URL="${LITELLM_BASE_URL}"
export OPENAI_API_KEY="${LITELLM_KEY}"
export PAPERCLIP_API_URL="${PAPERCLIP_API_URL:-http://paperclip:3100}"
export PAPERCLIP_URL="${PAPERCLIP_URL:-http://paperclip:3100}"
export PAPERCLIP_API_KEY="${PAPERCLIP_API_KEY:-}"
export PAPERCLIP_AGENT_ID="${PAPERCLIP_AGENT_ID:-}"
export PAPERCLIP_COMPANY_ID="${PAPERCLIP_COMPANY_ID:-}"
mkdir -p /usr/local/bin
if [ -x /app/paperclip-done.sh ]; then
  ln -sf /app/paperclip-done.sh /usr/local/bin/paperclip-done
fi
cat > /root/.hermes/AGENTS.md <<'AGENTS'
Al terminar una issue ejecuta exactamente:
paperclip-done ISSUE_ID "comentario breve"
ISSUE_ID es el UUID de la issue (no el codigo DIS-n).
Ese comando hace PATCH status=done. Un comentario Markdown no cierra la issue.
No uses ps, node, jwt ni execute_code.
AGENTS

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
