#!/usr/bin/env bash
set -euo pipefail

mkdir -p /root/.hermes /workspace /opt/data/workspace
# Hermes a veces busca /workspace; Paperclip usa otra ruta.
if [ ! -e /workspace/.keep ]; then
  touch /workspace/.keep
fi

LITELLM_BASE_URL="${LITELLM_BASE_URL:-http://litellm:4000/v1}"
LITELLM_KEY="${OPENAI_API_KEY:-${LITELLM_MASTER_KEY:-sk-litellm-proxy-internal}}"
DEFAULT_MODEL="${DEFAULT_MODEL:-gemini-flash}"
PORT="${PORT:-8080}"

# Gateway = unattended. deny + smart + 12 turns = hire bloqueado
# (HTTP interno flagged, jq ausente, espera de /approve que nadie ve).
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
  max_turns: 40
  disabled_toolsets:
    - code_execution

terminal:
  backend: local
  cwd: /workspace
  timeout: 120

platform_toolsets:
  api_server:
    - web
    - file
    - memory
    - terminal

approvals:
  mode: smart
  timeout: 20
  cron_mode: deny
  single_query_mode: approve
  unattended_mode: approve

command_allowlist:
  - paperclip-done
  - paperclip-hire
  - /usr/local/bin/paperclip-done
  - /usr/local/bin/paperclip-hire
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

# Hire helper: URL y key salen de env, no de la línea de comando (evita scan HIGH HTTP).
cat > /usr/local/bin/paperclip-hire <<'HIRE'
#!/usr/bin/env python3
import json, os, sys, urllib.error, urllib.request

def die(msg, code=2):
    print(msg, file=sys.stderr)
    sys.exit(code)

if len(sys.argv) < 3:
    die("uso: paperclip-hire NAME ROLE [TITLE] [REPORTS_TO]")

name = sys.argv[1]
role = sys.argv[2]
title = sys.argv[3] if len(sys.argv) > 3 else name
reports_to = sys.argv[4] if len(sys.argv) > 4 else os.environ.get("PAPERCLIP_AGENT_ID", "")

base = os.environ.get("PAPERCLIP_API_URL") or os.environ.get("PAPERCLIP_URL") or "http://paperclip:3100"
base = base.rstrip("/")
if base.endswith("/api"):
    base = base[:-4]
key = os.environ.get("PAPERCLIP_API_KEY") or ""
company = os.environ.get("PAPERCLIP_COMPANY_ID") or ""
if not key:
    die("PAPERCLIP_API_KEY no esta definida")
if not company:
    die("PAPERCLIP_COMPANY_ID no esta definida")

body = {
    "name": name,
    "role": role,
    "title": title,
    "reportsTo": reports_to or None,
    "capabilities": title,
    "adapterType": "hermes_gateway",
    "adapterConfig": {
        "apiBaseUrl": "http://hermes-adapter:8080",
        "paperclipApiUrl": "http://paperclip:3100",
        "timeoutSec": 1800,
        "sessionKeyStrategy": "issue",
        "dangerouslyAllowInsecureRemoteHttp": True,
    },
    "runtimeConfig": {"heartbeat": {"enabled": False, "wakeOnDemand": True}},
    "budgetMonthlyCents": 0,
}
data = json.dumps(body).encode()
req = urllib.request.Request(
    base + "/api/companies/" + company + "/agent-hires",
    data=data,
    method="POST",
    headers={
        "Authorization": "Bearer " + key,
        "Content-Type": "application/json",
    },
)
try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        raw = resp.read().decode()
except urllib.error.HTTPError as e:
    raw = e.read().decode() if e.fp else str(e)
    print(raw)
    sys.exit(1)
print(raw)
HIRE
chmod +x /usr/local/bin/paperclip-hire

cat > /root/.hermes/AGENTS.md <<'AGENTS'
Eres un agente Paperclip sobre Hermes. El Consejo humano aprueba hires.

Al contratar un colega NO uses curl, wget, jq ni URLs en la terminal.
Ejecuta exactamente:
paperclip-hire NAME ROLE TITLE
Ejemplo: paperclip-hire PHOENIX cmo "Director de Marketing"
Ese comando ya lleva adapter hermes_gateway e URLs internas.

Al terminar una issue:
paperclip-done ISSUE_ID "comentario breve"
ISSUE_ID es el UUID (no DIS-n). Un comentario Markdown no cierra la issue.

Workspace local: /workspace
No uses ps, node, jwt, execute_code ni abras dominios publicos.
No inventes http://oficina.dispersora.digital para APIs.
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
