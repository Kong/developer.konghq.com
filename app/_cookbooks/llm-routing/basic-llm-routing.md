---
popular: true
time_estimate: "15 min"
title: Basic LLM Routing
description: Route requests to any supported LLM provider through Kong AI Gateway.
content_type: cookbook
products:
  - ai-gateway
tools:
  - deck
canonical: true
works_on:
  - konnect
layout: cookbook
# Machine-readable fields for AI agent setup
agent_setup_url: "/kong-cookbooks/agent-setup/?recipe=/kong-cookbooks/basic-llm-routing/"
plugins:
  - ai-proxy-advanced
requires_embeddings: false
providers:
  - openai
  - anthropic
  - bedrock
  - azure
  - gemini
  - mistral

prereqs:
  inline:
    - title: Python
      include_content: prereqs/python
      icon_url: /assets/icons/python.svg
    - title: AI Credentials
      include_content: prereqs/ai-providers-credentials

---

{:.info}
> **Deploy this recipe automatically with an AI assistant.**
> <br/>
> Set `KONNECT_TOKEN` in your terminal, create a new directory for this recipe, then copy this link and provide it to your AI coding agent:
> `https://developer.konghq.com/kong-cookbooks/agent-setup/?recipe=/kong-cookbooks/basic-llm-routing/`
> Read through this page while the agent sets things up — it explains how the configuration works and what to expect.

## Overview

Route chat requests to any supported LLM provider through Kong AI Gateway — without changing your
client code. The [ai-proxy-advanced](/plugins/ai-proxy-advanced/) plugin sits between your
application and the upstream provider: it injects auth credentials, translates the request to the
provider's native format, and normalises the response back to OpenAI format before returning it to
the caller.

This solves a common problem: you want to swap providers (or test multiple providers) without
touching application code or distributing API keys to every service that makes LLM calls. Kong
holds the credentials; clients talk to a single stable endpoint.

{% mermaid %}
flowchart LR
    Client -->|"POST /basic-llm-routing<br>(OpenAI format)"| Kong[Kong AI Gateway]
    Kong -->|"injects auth<br>translates format"| LLM[LLM Provider]
    LLM -->|native response| Kong
    Kong -->|"OpenAI-format<br>response"| Client
{% endmermaid %}

## Prerequisites

### Google Gemini

This tutorial uses Google Gemini via Vertex AI:

1. [Create a Google Cloud project](https://console.cloud.google.com/) with Vertex AI enabled.
1. Create a service account and mount the JSON key file in your Kong container.
1. Create decK variables:

   ```sh
   export DECK_GCP_API_ENDPOINT='your-api-endpoint'
   export DECK_GCP_PROJECT_ID='your-project-id'
   export DECK_GCP_LOCATION_ID='us-central1'
   ```

## How it works

The recipe creates a single Kong service and route, with
[ai-proxy-advanced](/plugins/ai-proxy-advanced/) attached as a plugin. The plugin intercepts
each request, injects provider credentials, translates the request body to the provider's native
format, and normalises the response back to OpenAI format.

### Plugin config walkthrough

```yaml
plugins:
  - name: ai-proxy-advanced
    config:
      llm_format: openai
      targets:
        - route_type: llm/v1/chat
          auth:
            header_name: Authorization
            header_value: "Bearer <your-key>"
            allow_override: false
          logging:
            log_statistics: true
            log_payloads: true
          model:
            provider: openai
            name: gpt-4o
```

{:.no-copy-code}

**`route_type: llm/v1/chat`** — Selects the chat completions translation path. Kong accepts an
OpenAI-format `POST /v1/chat/completions` body and converts it to whatever format the upstream
provider expects (e.g. Anthropic's `messages` API, Bedrock's `invoke-model` body). The response
is always normalised back to OpenAI format.

**`auth`** — Kong holds provider credentials in the plugin config and injects them into every
upstream request. The client sends any value for `api_key` (the OpenAI SDK requires the field,
but Kong replaces it before forwarding). Set `auth.allow_override: true` if you want
client-provided credentials to pass through to the provider instead of being replaced — useful
when clients manage their own API keys and Kong is purely a routing layer.

**`logging.log_statistics`** — When enabled, Kong appends token usage data (`prompt_tokens`,
`completion_tokens`, `total_tokens`) to any attached logging plugin's output (e.g.
`http-log`, `file-log`). Useful for cost attribution.

**`logging.log_payloads`** — When enabled, the full request and response bodies are included in
the output of any attached logging plugin (`http-log`, `file-log`, etc.). Whether to enable this
depends on your organization's observability and compliance requirements.

**`model.name`** — Set this to the model you want to use — `gpt-4o`, `o3`, `claude-sonnet-4-5-20250929`,
etc. Change it and re-apply to switch models without changing any client code.

**Alternative configurations worth knowing about:**

- **`llm_format`** — This recipe uses the default (`openai`), which accepts OpenAI-format
  requests and normalises all provider responses back to OpenAI format. You can also set
  `llm_format` to a provider's native format (`anthropic`, `bedrock`, `gemini`, etc.) if your
  client already speaks that format and you don't want translation overhead.
- **`route_type: preserve`** — Instead of `llm/v1/chat`, you can use `preserve` to forward
  requests to an `upstream_path` without any body transformation. Useful when you need Kong for
  auth injection but want to call a provider-specific endpoint directly.

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

| Header                    | Description                                                      |
| ------------------------- | ---------------------------------------------------------------- |
| `X-Kong-Upstream-Latency` | Time (ms) Kong spent waiting for the provider to respond         |
| `X-Kong-Proxy-Latency`    | Time (ms) Kong spent processing the request (excluding upstream) |
| `X-Kong-LLM-Model`        | Model name selected for this request                             |

## Apply the Kong configuration

The following configuration creates a Kong Gateway service and route at `/basic-llm-routing`,
with the [ai-proxy-advanced](/plugins/ai-proxy-advanced/) plugin attached to handle provider
auth injection and format translation. All resources are scoped using `select_tags` and a kongctl
`namespace`, so they can be cleanly torn down without affecting other configurations on the same
control plane. See the [kongctl documentation](/kongctl/) for more on federated configuration
management.

Select your provider below, export the required environment variables, and apply.

{% navtabs "Providers" %}
{% tab OpenAI %}

Export your environment variables:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe'
export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
export DECK_CHAT_MODEL='gpt-4o'  # or gpt-4o-mini, o3
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
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

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve

rm -f kong-recipe.yaml
```
{: data-test-step="block" }

{% endtab %}
{% tab Anthropic %}

Export your environment variables:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe'
export DECK_ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
export DECK_CHAT_MODEL='claude-sonnet-4-5-20250929'  # or claude-haiku-4-5-20251001
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
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

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve

rm -f kong-recipe.yaml
```
{: data-test-step="block" }

{% endtab %}
{% tab AWS Bedrock %}

Export your environment variables:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe'
export DECK_AWS_ACCESS_KEY_ID='your-access-key'
export DECK_AWS_SECRET_ACCESS_KEY='your-secret-key'
export DECK_AWS_REGION='us-east-1'
export DECK_CHAT_MODEL='amazon.nova-pro-v1:0'  # or global.anthropic.claude-sonnet-4-5-20250929-v1:0
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
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

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve

rm -f kong-recipe.yaml
```
{: data-test-step="block" }

{% endtab %}
{% tab Azure %}

Export your environment variables:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe'
export DECK_AZURE_API_KEY='your-azure-api-key'
export DECK_AZURE_INSTANCE='your-instance-name'
export DECK_AZURE_DEPLOYMENT_ID='your-deployment-id'
export DECK_AZURE_API_VERSION='2024-12-01-preview'
export DECK_CHAT_MODEL='gpt-4o'  # matches your Azure deployment name
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
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

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve

rm -f kong-recipe.yaml
```
{: data-test-step="block" }

{% endtab %}
{% tab Google Gemini %}

Export your environment variables:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe'
export DECK_GCP_API_ENDPOINT='your-api-endpoint'
export DECK_GCP_PROJECT_ID='your-project-id'
export DECK_GCP_LOCATION_ID='us-central1'
export DECK_CHAT_MODEL='gemini-2.0-flash'  # or gemini-1.5-pro
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
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

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve

rm -f kong-recipe.yaml
```
{: data-test-step="block" }

{% endtab %}
{% tab Mistral %}

Export your environment variables:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe'
export DECK_MISTRAL_TOKEN='Bearer your-mistral-key'
export DECK_CHAT_MODEL='mistral-large-latest'  # or mistral-small-latest
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - basic-llm-routing-recipe
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

echo "
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve

rm -f kong-recipe.yaml
```
{: data-test-step="block" }

{% endtab %}
{% endnavtabs %}

## Try it out

The demo script sends a single chat request through Kong to your configured provider. It
uses the OpenAI SDK pointed at the Kong route — demonstrating that your client code stays
the same regardless of which provider is behind the gateway. Look for the `[LATENCY]` line
to confirm the request flowed through Kong, and the `[MODEL]` line to verify which model
responded.

Create the demo script:

```bash
cat <<'EOF' > demo.py
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
  1. Apply the recipe config (see README for the full kongctl apply command)
  2. Run:
       python demo.py
  3. Or pipe a prompt:
       echo "What is the capital of France?" | \
         python demo.py
"""

import os
import sys
import time

from openai import OpenAI, APIStatusError

CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o")

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")

# Kong overrides provider auth — the api_key value is required by the SDK but ignored
client = OpenAI(
    base_url=f"{PROXY_URL}/basic-llm-routing",
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

Run it:

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

The `[RESPONSE]` line shows the LLM's answer — Kong translated the request to the provider's
native format, forwarded it, and normalised the response back to OpenAI format before returning
it. The `[LATENCY]` breakdown shows how long the provider took (`upstream`) versus Kong's own
processing overhead (`proxy`). The `[MODEL]` header confirms which model actually served the
request, which is especially useful when testing provider switches.

## Cleanup

Because the recipe scoped all resources with `select_tags` and a kongctl `namespace`, the
teardown cleanly removes just this recipe's configuration without affecting anything else on the
control plane. Tear down the local data plane and delete the control plane from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```

## Variations and next steps

**Switch models** — update `DECK_CHAT_MODEL` to a different model (e.g. `gpt-4o-mini`, `o3`)
and re-apply. No other changes needed — the client endpoint stays the same.

**Switch providers** — select a different provider tab above, export that provider's credential
env vars alongside `DECK_CHAT_MODEL`, and re-apply. Note that switching providers requires
updating the auth-related env vars too, not just the config tab. For setups that route to
multiple providers simultaneously, see the
[ai-proxy-advanced load balancing documentation](/plugins/ai-proxy-advanced/).

**Add rate limiting** — attach the [ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/)
plugin to the same route to enforce per-consumer token quotas. See the
[AI rate limiting how-to guide](https://docs.konghq.com/gateway/latest/how-to/ai-gateway/ai-rate-limiting/)
for patterns.