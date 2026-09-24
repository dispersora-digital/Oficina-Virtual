#!/bin/sh
# LiteLLM >= 2026 exige LITELLM_MASTER_KEY. Hermes/Paperclip ya envían
# Authorization: Bearer ${LITELLM_MASTER_KEY}. Sin DB / virtual keys.
unset DATABASE_URL
if [ -z "${GEMINI_API_KEY:-}" ] && [ -n "${GOOGLE_API_KEY:-}" ]; then
  export GEMINI_API_KEY="${GOOGLE_API_KEY}"
fi
exec litellm --config /app/config.yaml --port 4000 --host 0.0.0.0
