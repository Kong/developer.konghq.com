---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Vertex AI
permalink: /how-to/use-claude-code-with-ai-gateway-vertex/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: File Log
    url: /plugins/file-log/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic using Google Vertex AI models

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.13'

plugins:
  - ai-proxy-advanced
  - file-log

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - vertex-ai

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}}?
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to Claude, enable file-log to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the {{site.ai_gateway}} for monitoring and control.

tools:
  - deck

prereqs:
  inline:
    - title: Vertex
      content: |
        Before you begin, you must get the following credentials from Google Cloud:

        - **Service Account Key**: A JSON key file for a service account with Vertex AI permissions
        - **Project ID**: Your Google Cloud project identifier
        - **Location ID**: The region where your Vertex AI endpoint is deployed (for example, `us-central1`)
        - **API Endpoint**: The Vertex AI API endpoint URL (typically `https://{location}-aiplatform.googleapis.com`)

        Export these values as environment variables:
        ```sh
        export GEMINI_API_KEY="<your_gemini_api_key>"
        export GCP_PROJECT_ID="<your-gemini-project-id>"
        export GEMINI_LOCATION_ID="<your-gemini-location_id>"
        export GEMINI_API_ENDPOINT="<your_gemini_api_endpoint>"
        ```
      icon_url: /assets/icons/vertex.svg
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code
  entities:
    services:
      - example-service
    routes:
      - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

automated_tests: false
---

## Configure the AI Proxy plugin

First, configure the AI Proxy plugin for the Gemini provider.
* This setup uses the default `llm/v1/chat` route. Claude Code sends its requests to this route.
* The configuration also raises the maximum tokens count size to 8192 to support larger prompts.

The `llm_format: anthropic` parameter tells {{site.ai_gateway}} to expect request and response payloads that match Claude's native API format. Without this setting, the Gateway would default to OpenAI's format, which would cause request failures when Claude Code communicates with the Gemini endpoint.

{% entity_examples %}
entities:
  plugins:
  - name: ai-proxy-advanced
    config:
      llm_format: anthropic
      targets:
        - route_type: llm/v1/chat
          logging:
            log_statistics: true
            log_payloads: false
          auth:
            allow_override: false
            gcp_use_service_account: true
            gcp_service_account_json: ${gcp_service_account_key}
          model:
              provider: gemini
              name: gemini-2.5-flash
              options:
                gemini:
                  api_endpoint: ${gcp_api_endpoint}
                  project_id: ${gcp_project_id}
                  location_id: ${gcp_location_id}
              max_tokens: 8192
variables:
  gcp_service_account_key:
    value: $GEMINI_API_KEY
  gcp_api_endpoint:
    value: $GEMINI_API_ENDPOINT
  gcp_project_id:
    value: $GCP_PROJECT_ID
  gcp_location_id:
    value: $GEMINI_LOCATION_ID
{% endentity_examples %}

## Configure the File Log plugin

Now, let's enable the [File Log](/plugins/file-log/) plugin on the Service, to inspect the LLM traffic between Claude and the {{site.ai_gateway}}. This creates a local `claude.json` file on your machine. The file records each request and response so you can review what Claude sends through the {{site.ai_gateway}}.

{% entity_examples %}
entities:
  plugins:
    - name: file-log
      config:
        path: "/tmp/claude.json"
{% endentity_examples %}

## Verify traffic through Kong

Now, we can start a Claude Code session that points it to the local {{site.ai_gateway}} endpoint:

{:.warning}
> Ensure that `ANTHROPIC_MODEL` matches the model you deployed in Gemini.

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=YOUR_VERTEX_MODEL \
claude
```

Claude Code asks for permission before it runs tools or interacts with files:

```text
I'll need permission to work with your files.

This means I can:
- Read any file in this folder
- Create, edit, or delete files
- Run commands (like npm, git, tests, ls, rm)
- Use tools defined in .mcp.json

Learn more ( https://docs.claude.com/s/claude-code-security )

❯ 1. Yes, continue
2. No, exit
```
{:.no-copy-code}

Select **Yes, continue**. The session starts. Ask a simple question to confirm that requests reach {{site.ai_gateway}}.

```text
Tell me about Anna Komnene's Alexiad.
```

Claude Code might prompt you approve its web search for answering the question. When you select **Yes**, Claude will produce a full-length response to your request:

```text
Anna Komnene (1083-1153?) was a Byzantine princess, scholar, physician,
hospital administrator, and historian. She is known for writing the
Alexiad, a historical account of the reign of her father, Emperor Alexios
I Komnenos (r. 1081-1118). The Alexiad is a valuable primary source for
understanding Byzantine history and the First Crusade.
```
{:.no-copy-code}

Next, inspect the {{site.ai_gateway}} logs to verify that the traffic was proxied through it:

```sh
docker exec kong-quickstart-gateway cat /tmp/claude.json | jq
```

You should find an entry that shows the upstream request made by Claude Code. A typical log record looks like this:

```json
{
  ...
  "method": "POST",
  "headers": {
    "user-agent": "claude-cli/2.0.37 (external, cli)",
    "content-type": "application/json"
  },
  ...
  "ai": {
    "proxy": {
      "tried_targets": [
        {
          "provider": "gemini",
          "model": "gemini-2.0-flash",
          "port": 443,
          "upstream_scheme": "https",
          "host": "us-central1-aiplatform.googleapis.com",
          "upstream_uri": "/v1/projects/example-project-id/locations/us-central1/publishers/google/models/gemini-2.0-flash:generateContent",
          "route_type": "llm/v1/chat",
          "ip": "xxx.xxx.xxx.xxx"
        }
      ],
      "meta": {
        "request_model": "gemini-2.5-flash",
        "request_mode": "oneshot",
        "response_model": "gemini-2.5-flash",
        "provider_name": "gemini",
        "llm_latency": 1694,
        "plugin_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      },
      "usage": {
        "completion_tokens": 19,
        "completion_tokens_details": {},
        "total_tokens": 11203,
        "cost": 0,
        "time_per_token": 85.157894736842,
        "time_to_first_token": 2546,
        "prompt_tokens": 11184,
        "prompt_tokens_details": {}
      }
    }
  }
  ...
}
```
{:.no-copy-code}

This output confirms that Claude Code routed the request through {{site.ai_gateway}} using the `gemini-2.5-flash` model we selected while starting the Claude Code session.
