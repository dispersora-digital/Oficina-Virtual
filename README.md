# Oficina-Virtual

Oficina de agentes de **Dispersora Digital** sobre Coolify.

```
Coolify proxy (HTTPS :443)
        │
        ▼
  Paperclip :3100          orquestador + UI
        │  hermes_gateway → http://hermes-adapter:8080
        ▼
  Hermes                   runtime de agentes
        │  OpenAI-compatible → http://litellm:4000/v1
        ▼
  LiteLLM :4000            gateway
        │  alias gemini-flash → gemini/gemini-3.6-flash
        ▼
  Google Gemini            AI Studio
```

La clave de Google vive solo en LiteLLM (`GEMINI_API_KEY`). Hermes y Paperclip hablan con `http://litellm:4000/v1`. No hace falta OpenAI.

---

## Estado del stack (2026-09-19)

**No se requiere más configuración de infraestructura** para Paperclip ↔ Hermes ↔ LiteLLM ↔ Gemini.

Validado en producción:

- UI Paperclip en `https://oficina.dispersora.digital`
- Health de Hermes OK
- `POST /v1/chat/completions` → 200
- Issues de prueba DIS-10 / DIS-11: un run, Status **Done**, `workspace_finalize` OK

Siguiente paso de producto (fuera de este archivo): crear la **empresa y agentes definitivos** en Paperclip. El piloto actual puede reutilizarse o sustituirse; no hace falta redeploy ni tocar volúmenes.

---

## Coolify (ya desplegado)

| Campo | Valor |
|---|---|
| App | DisDig Oficina Virtual / `paperclip-oficina-virtual` |
| Repo | `https://github.com/dispersora-digital/Oficina-Virtual.git` |
| Branch | `main` |
| Build pack | Public Git Repository + **Docker Compose** |
| Compose | `docker-compose.yaml` en la raíz |
| Dominio | **solo** Paperclip → `https://oficina.dispersora.digital` (puerto interno **3100**) |
| LiteLLM / Hermes | **sin dominio**, no publicar |

Reglas que no hay que revertir:

- `PAPERCLIP_DEPLOYMENT_EXPOSURE=private`  
  Si se pone `public`, Paperclip exige `DATABASE_URL` y rechaza el Postgres embebido.
- `PAPERCLIP_PUBLIC_URL=https://oficina.dispersora.digital` **sin** `:3100`
- No tocar `SERVICE_URL_*` ni `SERVICE_FQDN_*` (las genera Coolify)
- Deploy **con caché**. Deploy without cache rompió Hermes (`apt-get` exit 100). Solo without cache si cambia un Dockerfile.
- No borrar volúmenes (`paperclip_data`, `hermes_data`) ni reinstalar el stack

Admin UI: `administracion@dispersora.digital`

---

## Secretos Coolify (Production)

Obligatorios:

| Variable | Rol |
|---|---|
| `GEMINI_API_KEY` | AI Studio → LiteLLM |
| `LITELLM_MASTER_KEY` | Hermes/Paperclip → LiteLLM (Hermes la usa; LiteLLM la ignora a propósito) |
| `API_SERVER_KEY` | Paperclip → Hermes |
| `PAPERCLIP_API_KEY` | Hermes → Paperclip (clave de **agente** `pcp_` / `pc_agent_`, no es `API_SERVER_KEY`) |
| `BETTER_AUTH_SECRET` | Auth de la UI |
| `PAPERCLIP_AGENT_JWT_SECRET` | JWT de agentes |

Opcional: `DEFAULT_MODEL=gemini-flash`

Preview: no duplicar secretos salvo que usen Preview.

---

## Modelos LiteLLM

Cambia IDs de Gemini **solo** en `litellm-config.yaml`. El prefijo `gemini/` es obligatorio (sin él LiteLLM va a Vertex).

| Alias | Upstream |
|---|---|
| `gemini-flash` (default) | `gemini/gemini-3.6-flash` |
| `gemini-pro` | `gemini/gemini-3.1-pro-preview` |
| `gemini-3.6-flash` | `gemini/gemini-3.6-flash` |
| `gemini-3.5-flash` | `gemini/gemini-3.5-flash` |
| `gemini-2.5-flash` | alias → `gemini-3.6-flash` (2.5 ya no acepta claves nuevas) |
| `gemini-2.5-pro` / `gemini-1.5-pro` | alias → `gemini-3.1-pro-preview` |

`litellm-entrypoint.sh` hace `unset LITELLM_MASTER_KEY` para evitar `No connected db` sin Prisma. El warning `LITELLM_MASTER_KEY not set` en logs de LiteLLM es **interno y esperado**.

Ruido que se puede omitir:

- 404 en `/api/tags`, `/api/v1/models`, `/props`, `/version` → probes de Hermes
- Warning `temperature` / `top_p` / `top_k` en Gemini 3+ → LiteLLM los descarta (`drop_params`)

---

## Agente Paperclip (hermes_gateway)

Contratar / editar con **GET primero** y reenviar el `adapterConfig` entero. Un PATCH parcial puede sustituir el objeto y romper la config.

```json
{
  "adapterType": "hermes_gateway",
  "adapterConfig": {
    "apiBaseUrl": "http://hermes-adapter:8080",
    "timeoutSec": 1800,
    "paperclipApiUrl": "http://paperclip:3100",
    "dangerouslyAllowInsecureRemoteHttp": true
  }
}
```

- API key del gateway (Paperclip → Hermes) = `API_SERVER_KEY`
- `paperclipApiUrl` es la URL **interna** del compose, no el dominio público

APIs útiles (sesión en `oficina.dispersora.digital`):

- `GET /api/companies`
- `POST /api/companies/{companyId}/agent-hires`
- `PATCH /api/agents/{agentId}` — **no** `/api/companies/.../agents/...`

### Piloto actual (puede sustituirse)

| | ID |
|---|---|
| Empresa Dispersora Digital | `69a05954-6dfe-451c-b51a-de595c3f40f4` |
| Agente Oficina Gemini (CEO) | `6cf8b305-6eef-4c46-941f-29e1d67c01ab` |

`paperclip-done.sh` en `main` cierra issues con disposición real. Es **opcional**; solo aplica si el contenedor Hermes tiene `PAPERCLIP_API_KEY`. Si una issue queda Blocked con “missing disposition”, el board puede marcar Done a mano.

---

## Qué no tocar

- No reinstalar el resource de Coolify
- No borrar volúmenes ni la empresa de Paperclip “por limpieza”
- No publicar LiteLLM ni Hermes
- No poner `PAPERCLIP_DEPLOYMENT_EXPOSURE=public` sin Postgres externo
- No añadir `:3100` a `PAPERCLIP_PUBLIC_URL`
- No hace falta un provider OpenAI nativo
