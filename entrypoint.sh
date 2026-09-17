#!/usr/bin/env bash
set -e

# Crear el directorio base por si no existe
mkdir -p /root/.hermes

# 1. Configuración de interfaz y modelo base en config.yaml
cat <<EOF > /root/.hermes/config.yaml
dashboard:
  basic_auth:
    username: "admin"
    password_hash: "NO_SE_MUESTRA_POR_SEGURIDAD"

llm:
  provider: "google"
  model: "gemini-2.5-flash" # Puedes cambiarlo a gemini-2.5-pro según tu flujo
EOF

# 2. Inyección de la credencial en el archivo interno de Hermes (.env)
# Esto asegura que hermes serve lea la llave nativamente si no hereda el entorno de Docker
if [ -n "$GEMINI_API_KEY" ]; then
  echo "GEMINI_API_KEY=$GEMINI_API_KEY" > /root/.hermes/.env
  echo "Google Gemini API Key vinculada al entorno interno de Hermes."
fi

# 3. Arrancar el servicio de Hermes expuesto al contenedor de Paperclip
exec hermes serve --host 0.0.0.0 --port 8080
