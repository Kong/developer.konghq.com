---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
permalink: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - anthropic

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}}?
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to Claude, optionally enable file-log to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the {{site.ai_gateway}} for monitoring and control.

---

## Create an AI Provider entity

Create an [AI Provider](/ai-gateway/entities/ai-provider/) entity to define your connection to Anthropic and store your authentication credentials:

<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  type: anthropic
  display_name: generic-anthropic
  name: generic-anthropic
  config:
    auth:
      type: basic
      headers:
        - name: Authorization
          value: Bearer $ANTHROPIC_API_KEY
{% endkonnect_api_request %}
<!-- vale on -->

In this example, we're setting up the AI Provider with:

* `type: anthropic`: Specifies that this provider connects to the Anthropic service using Anthropic's standard API format.
* `name: generic-anthropic`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your Anthropic API key. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

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
  display_name: my-claude
  name: my-claude
  type: model
  formats:
    - type: anthropic
  config:
    route:
      paths:
        - /v1
    model: {}
    logging:
      payloads: false
      statistics: true
  targets:
    - name: claude-opus-4-6
      provider: generic-anthropic
      config:
        type: anthropic
  policies: []
  capabilities:
    - generate
{% endkonnect_api_request %}
<!-- vale on -->

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-claude`: A unique identifier for this model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format.
* `config.route.paths: [/v1]`: Configures the custom base path where this model's Routes will be accessible. Clients will send requests to paths that combine this base path with capability-specific Routes.
* `capabilities: [generate]`: Enables the text generation capability. The `generate` capability creates a `/chat/completions` endpoint, so combined with your base path, clients send chat requests to `/v1/chat/completions`.
* `targets`: Specifies which upstream AI Provider model to route requests to. Here, `provider: generic-anthropic` references the AI Provider we created earlier, and `name: claude-opus-4-6` specifies which Anthropic model to call upstream.
* `config.logging`: Configures what gets logged. With `statistics: true`, usage metrics (tokens, latency, cost) are logged for monitoring and billing. With `payloads: false`, full request/response bodies are not logged for privacy.

## Verify traffic through Kong

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=claude-sonnet-4-5-20250929 \
claude
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
Tell me about Madrid Skylitzes manuscript.
```

{{ site.claude_code }} might prompt you approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request:

```text
The Madrid Skylitzes is a remarkable 12th-century illuminated Byzantine
manuscript that represents one of the most important surviving examples
of medieval historical documentation. Here are the key details:

What it is

The Madrid Skylitzes is the only surviving illustrated manuscript of John
Skylitzes' "Synopsis of Histories" (Σύνοψις Ἱστοριῶν), which chronicles
Byzantine history from 811 to 1057 CE - covering the period from the death
of Emperor Nicephorus I to the deposition of Michael VI.

Artistic Significance

- 574 miniature paintings (with about 100 lost over time)
- Lavishly decorated with gold leaf, vibrant pigments, and intricate
detailing
- Depicts everything from imperial coronations and battles to daily life
in Byzantium
- The only surviving Byzantine illuminated chronicle written in Greek

Unique Collaboration

The manuscript is believed to be the work of 7 different artists from
various backgrounds:
- 4 Italian artists
- 1 English or French artist
- 2 Byzantine artists
```
{:.no-copy-code}
