#!/bin/sh
# LiteLLM en red interna de Coolify: sin DB y sin virtual keys.
# Coolify inyecta LITELLM_MASTER_KEY a todos los servicios; si LiteLLM
# lo toma como master_key, cualquier Bearer distinto (Hermes, health
# probes, discover_models) termina en HTTP 400 "No connected db".
unset LITELLM_MASTER_KEY
unset DATABASE_URL
exec litellm --config /app/config.yaml --port 4000 --host 0.0.0.0
