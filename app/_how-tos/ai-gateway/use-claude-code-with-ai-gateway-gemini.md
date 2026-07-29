---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Gemini
content_type: how_to
permalink: /ai-gateway/use-claude-code-with-ai-gateway-gemini/

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and OpenAI
    url: /ai-gateway/use-claude-code-with-ai-gateway-openai/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic to a Gemini model

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

prereqs:
  inline:
    - title: Gemini API key
      content: |
        1. Create a Gemini API key in [Google AI Studio](https://aistudio.google.com/apikey).
        1. Export the API key as a variable:
           ```bash
           export GEMINI_API_KEY='YOUR_GEMINI_API_KEY'
           ```

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - gemini

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} against a Gemini model?
  a: Create an AI Model Provider entity to store your Gemini API key, create an AI Model entity with an Anthropic-compatible format that routes to Gemini through that provider, then point Claude CLI's `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all LLM requests pass through the gateway for monitoring and control.

---

## Create an AI Model Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection to Gemini and store your API key:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: my-gemini-account
    ai_gateway: !lookup name:ai-quickstart
    name: my-gemini-account
    display_name: "my-gemini-account"
    type: gemini
    config:
      auth:
        type: basic
        headers:
        - name: x-goog-api-key
          value: !env GEMINI_API_KEY
{% endentity_examples %}

In this example, we're setting up the AI Model Provider with:

* `type: gemini`: Specifies that this provider connects to the Gemini service using Gemini's standard API format.
* `name: my-gemini-account`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your Gemini API key. `value: !env GEMINI_API_KEY` loads the value from your environment at apply time instead of embedding it in the YAML, and `kongctl` redacts it in plan and diff output. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

## Create an AI Policy entity

{{ site.claude_code }} sends beta headers, its own client credentials, and fields that Gemini's native API rejects. Create an [AI Policy](/ai-gateway/entities/ai-policy/) with a `request-transformer-advanced` config that strips the `anthropic-beta`, `authorization`, and `x-api-key` headers, the `beta` query string parameter, and the `output_config`/`context_management`/`mcp_servers`/`container`/`service_tier`/`reasoning_effort` body fields before the request reaches Gemini:

{% entity_examples %}
ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: !lookup name:ai-quickstart
    name: strip-claude-beta-info
    display_name: "strip-claude-beta-info"
    type: request-transformer-advanced
    config:
      remove:
        headers:
          - anthropic-beta
          - authorization
          - x-api-key
        querystring:
          - beta
        body:
          - output_config
          - context_management
          - mcp_servers
          - container
          - service_tier
          - reasoning_effort
{% endentity_examples %}

{:.info}
> {{ site.claude_code }} beta features vary by version and may add other incompatible fields over time. If you still see an error mentioning an unexpected field after applying this Policy, add that field to the appropriate `remove` list and re-apply.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: my-gemini-account
    ai_gateway: !lookup name:ai-quickstart
    name: my-gemini-account
    display_name: "my-gemini-account"
    type: gemini
    config:
      auth:
        type: basic
        headers:
        - name: x-goog-api-key
          value: !env GEMINI_API_KEY
ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: !lookup name:ai-quickstart
    name: strip-claude-beta-info
    display_name: "strip-claude-beta-info"
    type: request-transformer-advanced
    config:
      remove:
        headers:
          - anthropic-beta
          - authorization
          - x-api-key
        querystring:
          - beta
        body:
          - output_config
          - context_management
          - mcp_servers
          - container
          - service_tier
          - reasoning_effort
ai_gateway_models:
  - ref: my-claude-gemini
    ai_gateway: !lookup name:ai-quickstart
    name: my-claude-gemini
    display_name: "my-claude-gemini"
    type: model
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
      model:
        alias: my-claude-gemini
    targets:
      - name: gemini-2.5-flash
        provider: !ref my-gemini-account#name
        config:
          type: gemini
    policies:
      - !ref strip-claude-beta-info#name
    capabilities:
      - generate
{% endentity_examples %}

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-claude-gemini`: A unique identifier for this model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format, matching what {{ site.claude_code }} sends natively, even though the upstream model is Gemini.
* `config.route.paths: [/]`: Configures the custom base path where this model's routes will be accessible. Setting this to a unique value avoids clashes when you have multiple AI Models.
* `capabilities: [generate]`: Enables the text generation capability. For a model using the `anthropic` format, the `generate` capability creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with your base path, clients send requests to `/v1/messages`.
* `targets`: Specifies which upstream AI Model Provider model to route requests to. Here, `provider: !ref my-gemini-account#name` references the AI Model Provider we created earlier, and `name: gemini-2.5-flash` specifies which Gemini model to call upstream.
* `policies: [!ref strip-claude-beta-info#name]`: Attaches the AI Policy created earlier so it applies to every request to this AI Model.

## Validate the AI Model

Send a test request directly to confirm the setup works before pointing {{ site.claude_code }} at it:

```sh
curl -i -X POST http://localhost:8000/v1/messages \
  -H 'Content-Type: application/json' \
  -H 'anthropic-version: 2023-06-01' \
  --data '{
    "model": "my-claude-gemini",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "hello"}
    ]
  }'
```

## Verify traffic through Kong

{{ site.claude_code }}'s experimental beta features send fields that Gemini rejects even with the AI Policy in place. Disable them, then start a session pointed at your local {{site.ai_gateway}} endpoint:

```sh
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1

ANTHROPIC_BASE_URL=http://localhost:8000/ \
ANTHROPIC_MODEL=my-claude-gemini \
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
Tell me about Anna Komnene's Alexiad.
```

{{ site.claude_code }} might prompt you approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request, proxied through {{site.ai_gateway}} to the Gemini model configured in the AI Model entity's `targets`.
