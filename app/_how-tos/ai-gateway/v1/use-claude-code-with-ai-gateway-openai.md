---
title: Route Claude CLI traffic through {{site.ai_gateway}} and OpenAI
permalink: /ai-gateway/v1/how-to/use-claude-code-with-ai-gateway-openai/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/v1/
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: File Log
    url: /plugins/file-log/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic using OpenAI models

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
  - openai

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}}?
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to Claude, enable the File Log plugin to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the {{site.ai_gateway}} for monitoring and control.

tools:
  - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
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
major_version:
  ai-gateway: 1

---

## Create an AI Provider entity

Create an [AI Provider](/ai-gateway/entities/ai-provider/) entity to define your connection to Anthropic and store your authentication credentials:

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/model-providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  type: anthropic
  display_name: openai-anthropic
  name: openai-anthropic
  config:
    auth:
      type: basic
      headers:
        - name: x-api-key
          value: $OPENAI_API_KEY
{% endkonnect_api_request %}
<!-- vale on -->

In this example, we're setting up the AI Provider with:

* `type: anthropic`: Specifies that this provider connects to the Anthropic service using Anthropic's standard API format. This is important when using an alternate provider with Claude Code. Without this setting, {{site.ai_gateway}} would default to OpenAI’s format, which would cause request failures when Claude Code communicates with the OpenAI endpoint.
* `name: openai-anthropic`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your API key. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Provider to use:

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/models
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: gpt-for-claude
  name: gpt-for-claude
  type: model
  formats:
    - type: anthropic
  config:
    route:
      paths:
        - /
    model: {
      alias: gpt-for-claude
    }
    logging:
      payloads: false
      statistics: true
  targets:
    - name: gpt-5.6-luna
      provider: openai-anthropic
      config:
        type: anthropic
  policies: []
  capabilities:
    - generate
{% endkonnect_api_request %}
<!-- vale on -->

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: gpt-for-claude`: A unique identifier for this model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format.
* `config.route.paths: [/]`: Configures the custom base path where this model's Routes will be accessible. Setting this to a unique value avoids clashes when you have multiple AI Models.
* `capabilities: [generate]`: Enables the text generation capability. The `generate` capability creates a `/chat/completions` endpoint, so combined with your base path, clients send chat requests to `/v1/chat/completions`.
* `targets`: Specifies which upstream AI Provider model to route requests to. Here, `provider: openai-anthropic` references the AI Provider we created earlier, and `name: gpt-5.6-luna` specifies which Anthropic model to call upstream.
* `config.logging`: Configures what gets logged. With `statistics: true`, usage metrics (tokens, latency, cost) are logged for monitoring and billing. With `payloads: false`, full request/response bodies are not logged for privacy.

## Verify traffic through {{site.ai_gateway}}

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/ claude --model 'gpt-for-claude'
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
Tell me about Procopius' Secret History.
```

{{ site.claude_code }} might prompt you approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request:

```text
Procopius’ Secret History (Greek: Ἀνέκδοτα, Anekdota) is a fascinating and
notorious work of Byzantine literature written in the 6th century by the
court historian Procopius of Caesarea. Unlike his official histories
(“Wars” and “Buildings”), which paint the Byzantine Emperor Justinian I
and his wife Theodora in a generally positive and conventional manner, the
Secret History offers a scandalous, behind-the-scenes account that
sharply criticizes and even vilifies the emperor, the empress, and other
key figures of the time.
```
{:.no-copy-code}