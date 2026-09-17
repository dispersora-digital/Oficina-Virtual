#!/usr/bin/env bash
set -e

mkdir -p /root/.hermes

# Generar configuración de Hermes con autenticación básica si no existe
cat <<EOF > /root/.hermes/config.yaml
dashboard:
  basic_auth:
    username: "admin"
    password_hash: "pbkdf2:sha256:600000\$xK8jW2\$4c6198f16b23b8fbcad2dc8f4d99c35a8bc3e414163bb4beabf62804b9e4a8dc"
llm:
  provider: "google"
  model: "gemini-2.5-pro" # O "gemini-2.5-flash" cambiar según necesidades de rendimiento/costo
EOF

# Ejecutar hermes serve
exec hermes serve --host 0.0.0.0 --port 8080
