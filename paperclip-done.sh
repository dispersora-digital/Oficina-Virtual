#!/bin/sh
# Cierra una issue de Paperclip con disposición real (status=done).
# Uso: paperclip-done <issueId> [comentario]
set -eu

ISSUE_ID="${1:-}"
COMMENT="${2:-Tarea completada.}"
BASE="${PAPERCLIP_API_URL:-${PAPERCLIP_URL:-http://paperclip:3100}}"
KEY="${PAPERCLIP_API_KEY:-}"

if [ -z "$ISSUE_ID" ]; then
  echo "uso: paperclip-done <issueId> [comentario]" >&2
  exit 2
fi
if [ -z "$KEY" ]; then
  echo "PAPERCLIP_API_KEY no esta definida" >&2
  exit 2
fi

BASE="${BASE%/}"
case "$BASE" in
  */api) BASE="${BASE%/api}" ;;
esac

BODY=$(python3 -c 'import json,sys; print(json.dumps({"status":"done","comment":sys.argv[1]}))' "$COMMENT")

set -- \
  -sS \
  -X PATCH \
  -H "Authorization: Bearer ${KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY"

if [ -n "${PAPERCLIP_RUN_ID:-}" ]; then
  set -- -H "X-Paperclip-Run-Id: ${PAPERCLIP_RUN_ID}" "$@"
fi

RESP=$(curl "$@" "${BASE}/api/issues/${ISSUE_ID}")
echo "$RESP"
echo "$RESP" | python3 -c 'import json,sys
raw=sys.stdin.read()
try:
  d=json.loads(raw)
except Exception:
  sys.exit(0)
status=d.get("status") or (d.get("issue") or {}).get("status") or ""
if status and status != "done":
  print("WARN: status="+str(status), file=sys.stderr)
  sys.exit(1)
'
