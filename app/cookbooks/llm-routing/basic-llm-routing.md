---
content_type: cookbook
products:
    - ai-gateway
tools:
    - deck
layout: reference
title: Basic LLM Routing
description: Route requests to any supported LLM provider through Kong AI Gateway.
---

## Overview

Route chat requests to any supported LLM provider through Kong AI Gateway — without changing your client code. The `ai-proxy-advanced` plugin sits between your application and the upstream provider: it injects auth credentials, translates the request to the provider's native format, and normalises the response back to OpenAI format before returning it to the caller.

This solves a common problem: you want to swap providers (or test multiple providers) without touching application code or distributing API keys to every service that makes LLM calls. Kong holds the credentials; clients talk to a single stable endpoint.

**Request flow:**

```
Client (OpenAI SDK)
       │  POST /basic-llm-routing
       ▼
Kong AI Gateway
  └─ ai-proxy-advanced
       │  injects auth, translates format
       ▼
LLM Provider (OpenAI / Anthropic / Bedrock / Azure / Gemini / Mistral)
       │  native response
       ▼
Kong AI Gateway
  └─ normalises to OpenAI format
       │
       ▼
Client ← standard ChatCompletion response
```

## Prerequisites

- [Docker Compose](https://docs.docker.com/compose/install/) installed
- [deck CLI](https://docs.konghq.com/deck/latest/installation/) installed and on `PATH`
- Python 3.9+
- Credentials for at least one supported provider (OpenAI API key, AWS credentials for Bedrock, etc.)

## Setup

**1. Start Kong Gateway, PostgreSQL, and Redis:**

First, we need to create a `docker-compose.yaml` file. This file will define the services we want to run in our local environment:

```bash
cat <<EOF > docker-compose.yaml
version: "2.2"

# Specify which Kong image to run
x-kong-image: &kong-image
  # image: kong/kong-gateway-dev:master
  # image: kong/kong-gateway:3.12
  # image: kongcx/kongps-public:3.11.0.3-arm
  image: kong/kong-gateway:3.13

# Prompt compressor image — update the tag here to upgrade
x-compressor-image: &compressor-image
  image: docker.cloudsmith.io/kong/ai-compress/service:v0.0.2

# Kong database config
x-kong-db-config: &kong-db-config
  KONG_DATABASE: postgres
  KONG_PG_HOST: db
  KONG_PG_DATABASE: kong
  KONG_PG_USER: kong
  KONG_PG_PASSWORD: kong
  KONG_PASSWORD: password

x-kong-container-common: &kong-container-common
  healthcheck:
    test: ["CMD", "kong", "health"]
    interval: 3s
    timeout: 3s
    retries: 10
    start_period: 3s
  restart: on-failure
  tmpfs:
    - /tmp
networks:
  kong:
    name: kong
    driver: bridge

services:
  kong-migrations:
    <<: *kong-image
    networks:
      - kong
    command: "kong migrations bootstrap"
    env_file:
      - "./.env"
    environment:
      <<: [*kong-db-config]
    restart: on-failure

  kong-migrations-upgrade:
    <<: *kong-image
    profiles: ["upgrade", "everything"]
    networks:
      - kong
    command: "kong migrations up"
    env_file:
      - "./.env"
    environment:
      <<: [*kong-db-config]
      KONG_ANONYMOUS_REPORTS: "off"
    restart: on-failure

  kong-migrations-finish:
    <<: *kong-image
    profiles: ["upgrade-finish", "everything"]
    networks:
      - kong
    command: "kong migrations finish"
    env_file:
      - "./.env"
    environment:
      <<: [*kong-db-config]
      KONG_ANONYMOUS_REPORTS: "off"
    restart: on-failure

  kong-gateway:
    <<: [*kong-container-common, *kong-image]
    deploy:
      replicas: 1
    mem_limit: 2g
    cpus: 4
    networks:
      - kong
    user: "${KONG_USER:-kong}"
    ports:
      - 8000:8000
      - 8001:8001
      - 8002:8002
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - "$HOME/.aws:/home/kong/.aws"
    env_file:
      - "./.env"
    environment:
      <<: [*kong-db-config]
      KONG_ANONYMOUS_REPORTS: "off"
      KONG_PROXY_LISTEN: "0.0.0.0:8000,0.0.0.0:8443 ssl"
      KONG_ADMIN_LISTEN: "0.0.0.0:8001"
      KONG_ADMIN_GUI_LISTEN: "0.0.0.0:8002"
      KONG_LOG_LEVEL: "debug"
      KONG_UNTRUSTED_LUA_SANDBOX_REQUIRES: cjson,kong,resty.http,kong.constants
      KONG_RESOLVER_FAMILY: "A"
      AWS_PROFILE: "sandbox"
      KONG_LICENSE_DATA: ${KONG_LICENSE_DATA}

  redis:
    image: redis/redis-stack-server
    deploy:
      replicas: 1
    mem_limit: 1g
    cpus: 1
    ports:
      - 6378:6379
    networks:
      - kong

  # Required for: cost-optimization/prompt-compression
  # The image is hosted in Kong's private Cloudsmith registry.
  # Contact Kong support or your account team to obtain registry credentials,
  # then add them to docker_username.txt and docker_password.txt at the repo root.
  # Start with: docker-compose --profile compression up -d
  prompt-compressor:
    <<: *compressor-image
    profiles: ["compression"]
    deploy:
      replicas: 1
    mem_limit: 2g
    cpus: 1
    ports:
      - 8080:8080
    networks:
      - kong
    environment:
      LLMLINGUA_DEVICE_MAP: "cpu"
    secrets:
      - kong_registry_username
      - kong_registry_password

  #########################################################
  # AI PII SERVICE DOES NOT WORK WITH ARM64 ARCHITECTURE
  #########################################################
  # AI PII SERVICE DOES NOT WORK WITH ARM64 ARCHITECTURE
  # ai-pii-service:
  #   image: kong/ai-pii-service:latest
  #   deploy:
  #     replicas: 1
  #   mem_limit: 1g
  #   cpus: 1
  #   ports:
  #     - 9000:9000
  #   networks:
  #     - kong
  #     # - aigateway-net
  #     # - aigateway-net-internal

  db:
    networks:
      - kong
    image: postgres:14-alpine
    environment:
      POSTGRES_DB: kong
      POSTGRES_PASSWORD: kong
      POSTGRES_USER: kong
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "kong"]
      interval: 3s
      timeout: 3s
      retries: 10
      start_period: 3s
    restart: on-failure
    stdin_open: true
    tty: true

secrets:
  kong_registry_username:
    file: ./docker_username.txt
  kong_registry_password:
    file: ./docker_password.txt
EOF
```
{:.collapsible}

Now, let’s start the local setup:

```bash
docker-compose up -d
```

**2. Configure credentials:**


```bash
cat <<EOF > .env
# ============================================================
# Kong AI Gateway Cookbook — Environment Variables
# ============================================================
# Copy this file to .env and fill in your credentials.
# You only need to configure the providers you plan to use.
#
# MINIMUM REQUIRED: At least one LLM provider credential
# ============================================================

# ------------------------------------------------------------
# Provider Credentials
# ------------------------------------------------------------

# OpenAI
# Get your key: https://platform.openai.com/api-keys
# Include the Bearer prefix: DECK_OPENAI_TOKEN=Bearer sk-...
DECK_OPENAI_TOKEN=

# Anthropic
# Get your key: https://console.anthropic.com/
DECK_ANTHROPIC_TOKEN=

# AWS Bedrock
# Note: Alternatively, mount $HOME/.aws credentials (see docker-compose.yaml)
DECK_AWS_ACCESS_KEY_ID=
DECK_AWS_SECRET_ACCESS_KEY=
DECK_AWS_REGION=

# Azure OpenAI
# Get your key: Azure Portal > Your OpenAI resource > Keys and Endpoint
DECK_AZURE_API_KEY=
DECK_AZURE_INSTANCE=
DECK_AZURE_DEPLOYMENT_ID=
DECK_AZURE_EMBEDDINGS_DEPLOYMENT_ID=
DECK_AZURE_API_VERSION=

# Google Gemini (via Vertex AI)
# Requires a service account JSON file mounted in the Kong container
DECK_GCP_API_ENDPOINT=
DECK_GCP_PROJECT_ID=
DECK_GCP_LOCATION_ID=

# Mistral
# Get your key: https://console.mistral.ai/api-keys/
# Include the Bearer prefix: DECK_MISTRAL_TOKEN=Bearer ...
DECK_MISTRAL_TOKEN=

# ------------------------------------------------------------
# Model Selection
# ------------------------------------------------------------
# Set these to the model IDs for the provider you are deploying.
# Valid model IDs vary by provider — see supported providers:
# https://developer.konghq.com/plugins/ai-proxy-advanced/#supported-ai-providers

# Chat model used by all recipes.
# Examples:
#   OpenAI:      gpt-4o, gpt-4o-mini, o3
#   Anthropic:   claude-sonnet-4-5-20250929
#   Bedrock:     global.anthropic.claude-sonnet-4-5-20250929-v1:0, amazon.nova-pro-v1:0
#   Azure:       gpt-4o  (matches your deployment name)
#   Gemini:      gemini-2.0-flash
#   Mistral:     mistral-large-latest
DECK_CHAT_MODEL=

# Embeddings model — used by semantic-caching and semantic-prompt-guard.
# Only required for providers with embeddings support (OpenAI, Bedrock, Azure).
# Examples:
#   OpenAI:  text-embedding-3-large, text-embedding-3-small
#   Bedrock: amazon.titan-embed-text-v2:0
#   Azure:   text-embedding-3-large  (matches your embeddings deployment name)
DECK_EMBEDDINGS_MODEL=

# Embedding vector dimensions — must exactly match your chosen embeddings model.
# Getting this wrong causes silent cache failures (wrong vector size in Redis).
# Common values:
#   text-embedding-3-large       → 3072
#   text-embedding-3-small       → 1536
#   text-embedding-ada-002       → 1536
#   amazon.titan-embed-text-v2:0 → 1024
DECK_EMBEDDINGS_DIMENSIONS=

# ------------------------------------------------------------
# Recipe-Specific Config
# ------------------------------------------------------------

# AWS Guardrails (required for guardrails/aws-guardrails)
DECK_AWS_GUARDRAIL_ID=
DECK_AWS_GUARDRAIL_VERSION=

# Azure Content Safety (required for guardrails/azure-content-safety)
# Get your endpoint and key: Azure Portal > Content Safety resource
DECK_AZURE_CONTENT_SAFETY_URL=
DECK_AZURE_CONTENT_SAFETY_KEY=

# PII Sanitizer service (required for guardrails/sanitize-pii-data)
# Host of the external PII detection service reachable from Kong container
DECK_PII_SERVICE_HOST=

# Prompt Compression service (required for cost-optimization/prompt-compression)
# URL of the LLMLingua-compatible compression service
DECK_COMPRESSOR_URL=
EOF
```
{:.collapsible}

Edit `.env` and fill in the credentials for your chosen provider.

**3. Export env vars for deck:**

```bash
set -a; source .env; set +a
```

**4. Create and activate a virtual environment** (optional but recommended):

```bash
python -m venv .venv
source .venv/bin/activate
```

**5. Install Python dependencies:**

First, create a file with the dependencies.

```bash
cat <<EOF > requirements.txt
openai>=1.0.0
EOF
```

Then, install them:

```bash
pip install -r requirements.txt
```

**6. Sync the recipe config to Kong:**

Create a directory to store the deck files:

```bash
mkdir deck
```

{% navtabs "Providers" %}
{% tab Anthropic %}
```bash
{%- raw %}
cat <<'EOF' > deck/anthropic.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: x-api-key
          header_value: ${{ env "DECK_ANTHROPIC_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: anthropic
          name: ${{ env "DECK_CHAT_MODEL" }}
EOF
{% endraw -%}
```

Sync the config:
```bash
deck gateway sync --no-mask-deck-env-vars-value deck/anthropic.yaml
```
{% endtab %}

{% tab Azure %}
```bash
{%- raw %}
cat <<'EOF' > deck/azure.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: api-key
          header_value: ${{ env "DECK_AZURE_API_KEY" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: azure
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            azure_api_version: ${{ env "DECK_AZURE_API_VERSION" }}
            azure_deployment_id: ${{ env "DECK_AZURE_DEPLOYMENT_ID" }}
            azure_instance: ${{ env "DECK_AZURE_INSTANCE" }}
EOF
{% endraw -%}
```

Sync the config:
```bash
deck gateway sync --no-mask-deck-env-vars-value deck/azure.yaml
```
{% endtab %}

{% tab Bedrock %}
```bash
{%- raw %}
cat <<'EOF' > deck/bedrock.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      targets:
      - route_type: llm/v1/chat
        auth:
          aws_access_key_id: ${{ env "DECK_AWS_ACCESS_KEY_ID" }}
          aws_secret_access_key: ${{ env "DECK_AWS_SECRET_ACCESS_KEY" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: bedrock
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            bedrock:
              aws_region: ${{ env "DECK_AWS_REGION" }}
EOF
{% endraw -%}
```

Sync the config:
```bash
deck gateway sync --no-mask-deck-env-vars-value deck/bedrock.yaml
```
{% endtab %}

{% tab Gemini %}
```bash
{%- raw %}
cat <<'EOF' > deck/gemini.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      targets:
      - route_type: llm/v1/chat
        auth:
          gcp_use_service_account: true
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: gemini
          name: ${{ env "DECK_CHAT_MODEL" }}
          options:
            gemini:
              api_endpoint: ${{ env "DECK_GCP_API_ENDPOINT" }}
              project_id: ${{ env "DECK_GCP_PROJECT_ID" }}
              location_id: ${{ env "DECK_GCP_LOCATION_ID" }}
EOF
{% endraw -%}
```

Sync the config:
```bash
deck gateway sync --no-mask-deck-env-vars-value deck/gemini.yaml
```
{% endtab %}

{% tab Mistral %}
```bash
{%- raw %}
cat <<'EOF' > deck/mistral.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_MISTRAL_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: mistral
          name: ${{ env "DECK_CHAT_MODEL" }}
EOF
{% endraw -%}
```

Sync the config:
```bash
deck gateway sync --no-mask-deck-env-vars-value deck/mistral.yaml
```
{% endtab %}

{% tab OpenAI %}
```bash
cat <<'EOF' > deck/openai.yaml
{%- raw %}
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing
services:
- name: basic-llm-routing
  url: http://localhost
  routes:
  - name: basic-llm-routing
    paths:
    - /basic-llm-routing
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    instance_name: basic-llm-routing-proxy
    config:
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL" }}
EOF
{% endraw -%}
```

Sync the config:
```bash
deck gateway sync --no-mask-deck-env-vars-value deck/openai.yaml
```
{% endtab %}
{% endnavtabs %}


## How it works

The recipe creates a single Kong service and route, with [ai-proxy-advanced](/plugins/ai-proxy-advanced/) attached as a plugin.

### Plugin config walkthrough

```yaml
plugins:
  - name: ai-proxy-advanced
    config:
      targets:
        - route_type: llm/v1/chat   # Tells Kong this is a chat completions operation.
                                    # Kong translates the OpenAI-format body to the
                                    # provider's native format before forwarding.
          auth:
            header_name: Authorization
            header_value: "Bearer <your-key>"  # Injected by Kong; never sent by the client.
          logging:
            log_statistics: true   # Adds token usage and model metrics to Kong log output.
            log_payloads: true     # Logs the full request/response body for debugging.
          model:
            provider: openai       # Resolved from the provider registry at generate time.
            name: gpt-4o           # Resolved from DECK_CHAT_MODEL env var at sync time.
```
 {:.no-copy-code}

- **`route_type: llm/v1/chat`** — Selects the chat completions translation path. Kong accepts an OpenAI-format `POST /v1/chat/completions` body and converts it to whatever format the upstream provider expects (e.g. Anthropic's `messages` API, Bedrock's `invoke-model` body). The response is always normalised back to OpenAI format.

- **`auth`** — Credentials are stored in Kong config (sourced from env vars at `deck gateway sync` time). The client sends `api_key="placeholder"`; Kong replaces the Authorization header before forwarding the request upstream.

- **`logging.log_statistics`** — When enabled, Kong appends token usage data (`prompt_tokens`, `completion_tokens`, `total_tokens`) to any attached logging plugin's output (e.g. `http-log`, `file-log`). Useful for cost attribution.

- **`model.name`** — Resolves to `{%raw%}${{ env "DECK_CHAT_MODEL" }}{%endraw%}` in the generated deck file. The actual model name is substituted at `deck gateway sync` time, so you can change models by updating `.env` and re-syncing without regenerating files.

### Example request and response

Request (sent by the OpenAI SDK to Kong):

```json
POST http://localhost:8000/basic-llm-routing
{
  "model": "gpt-4o",
  "messages": [
    { "role": "user", "content": "What is the capital of France?" }
  ]
}
```
 {:.no-copy-code}

Response (Kong normalises the upstream reply to OpenAI format):

```json
{
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "model": "gpt-4o",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Paris is the capital of France."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 14,
    "completion_tokens": 9,
    "total_tokens": 23
  }
}
```
 {:.no-copy-code}
 
Kong adds the following response headers:

| Header | Description |
|--------|-------------|
| `X-Kong-Upstream-Latency` | Time (ms) Kong spent waiting for the provider to respond |
| `X-Kong-Proxy-Latency` | Time (ms) Kong spent processing the request (excluding upstream) |
| `X-Kong-LLM-Model` | Model name selected for this request |

## Verify it's working

```bash
cat <<EOF > demo.py
"""
Basic LLM Routing — demo script
================================
Demonstrates routing a chat request through Kong AI Gateway to any supported
LLM provider using the ai-proxy-advanced plugin.

Expected output:
  [REQUEST] What is the capital of France?
  [RESPONSE] Paris is the capital of France.
  [LATENCY] upstream=312ms  proxy=4ms
  [MODEL] gpt-4o

How to run:
  1. Sync the recipe:
       deck gateway sync --no-mask-deck-env-vars-value \\
         recipes/llm-routing/basic-llm-routing/deck/openai.yaml
  2. Run:
       python recipes/llm-routing/basic-llm-routing/demo.py
  3. Or pipe a prompt:
       echo "What is the capital of France?" | \\
         python recipes/llm-routing/basic-llm-routing/demo.py
"""

import os
import sys
import time

from openai import OpenAI, APIStatusError

CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o")

# Kong overrides provider auth — the api_key value is required by the SDK but ignored
client = OpenAI(
    base_url="http://localhost:8000/basic-llm-routing",
    api_key="placeholder",
)

if sys.stdin.isatty():
    prompt = input("Ask: ").strip()
else:
    prompt = sys.stdin.read().strip()

if not prompt:
    print("No prompt provided. Exiting.")
    sys.exit(1)

print(f"\n[REQUEST] {prompt}")

start_ms = round(time.time() * 1000)
try:
    raw = client.chat.completions.with_raw_response.create(
        model=CHAT_MODEL,
        messages=[{"role": "user", "content": prompt}],
    )
    elapsed_ms = round(time.time() * 1000) - start_ms
    completion = raw.parse()

    upstream_latency = raw.headers.get("x-kong-upstream-latency", "—")
    proxy_latency = raw.headers.get("x-kong-proxy-latency", "—")
    llm_model = raw.headers.get("x-kong-llm-model", CHAT_MODEL)

    answer = completion.choices[0].message.content
    print(f"[RESPONSE] {answer}")
    print(f"[LATENCY] upstream={upstream_latency}ms  proxy={proxy_latency}ms  total={elapsed_ms}ms")
    print(f"[MODEL] {llm_model}")

except APIStatusError as e:
    elapsed_ms = round(time.time() * 1000) - start_ms
    print(f"[ERROR] {e.status_code} — {e.message}  ({elapsed_ms}ms)")
    sys.exit(1)
EOF
```
{:.collapsible}

Run the demo script:

```bash
python demo.py
```

Example output:

```
Ask: What is the capital of France?

[REQUEST] What is the capital of France?
[RESPONSE] Paris is the capital of France.
[LATENCY] upstream=312ms  proxy=4ms  total=320ms
[MODEL] gpt-4o
```
 {:.no-copy-code}

Confirm the plugin is active via the Admin API:

```bash
curl -s http://localhost:8001/plugins \
  | jq '[.data[] | select(.name == "ai-proxy-advanced")] | .[0] | {id, name, enabled}'
```

Expected output:

```json
{
  "id": "a1b2c3d4-...",
  "name": "ai-proxy-advanced",
  "enabled": true
}
```
{:.no-copy-code}

## Variations and next steps

**Switch providers without changing client code** — run `deck gateway sync` with a different provider file (e.g. `deck/anthropic.yaml`) and update `DECK_CHAT_MODEL` in `.env` to a model that provider supports. The client endpoint stays the same.

**Add load balancing across providers** — extend `scaffold.yaml` with a second entry in the `targets` list and set `weight` values. `ai-proxy-advanced` will distribute traffic between providers. See the [llm-load-balancing](../llm-load-balancing/) recipe for a complete example.

**Add rate limiting** — attach the `ai-rate-limiting-advanced` plugin to the same route to enforce per-consumer token quotas. See the [rate-limiting](../../rate-limiting/) recipes for patterns.