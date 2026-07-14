---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Vertex AI
permalink: /ai-gateway/use-claude-code-with-ai-gateway-vertex/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic using Google Vertex AI models

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - vertex-ai

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}}?
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to Claude, enable file-log to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the {{site.ai_gateway}} for monitoring and control.

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
        export VERTEX_UPSTREAM_URL="<your_upstream_url>"
        export GCP_SERVICE_ACCOUNT_JSON="<your_account_json>"
        ```
      icon_url: /assets/icons/vertex.svg
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

---

## Create an AI Provider entity

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    name: ai-quickstart
    display_name: "ai-quickstart"

ai_gateway_model_providers:
  - ref: vertex-prod
    name: vertex-prod
    display_name: "Google Vertex Prod"
    ai_gateway: ai-quickstart
    type: vertex
    config:
      auth:
        type: gcp
        service_account_json: !env GCP_SERVICE_ACCOUNT_JSON
EOF
```

In this example, we're setting up the AI Model Provider with:

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Provider to use:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    name: ai-quickstart
    display_name: "ai-quickstart"

ai_gateway_models:
  - ref: claude-code-vertex-sonnet
    type: model
    name: claude-code-vertex-sonnet
    display_name: "Claude Code - Vertex - Sonnet 4.6"
    ai_gateway: ai-quickstart
    enabled: true
    config:
      route:
        paths:
        - /
      model:
        alias: "claude-code-vertex-sonnet"
    formats:
      - type: anthropic
    targets:
      - name: claude-sonnet-4-6
        provider: vertex-prod
        config:
          type: vertex
          upstream_url: !env VERTEX_UPSTREAM_URL
    capabilities:
      - generate
EOF
```

In this example, we're setting up the AI Model with:

## Verify traffic through Kong

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

{:.warning}
> Ensure that `ANTHROPIC_MODEL` matches the model you deployed in Gemini.

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/ claude --model 'claude-code-vertex-sonnet'
```

{{ site.claude_code }} asks for permission before it runs tools or interacts with files:

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

{{ site.claude_code }} might prompt you approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request:

```text
Anna Komnene (1083-1153?) was a Byzantine princess, scholar, physician,
hospital administrator, and historian. She is known for writing the
Alexiad, a historical account of the reign of her father, Emperor Alexios
I Komnenos (r. 1081-1118). The Alexiad is a valuable primary source for
understanding Byzantine history and the First Crusade.
```
{:.no-copy-code}
