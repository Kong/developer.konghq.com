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
  - text: AI Model Provider
    url: /ai-gateway/entities/ai-model-provider/

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
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

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

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection and store your authentication credentials:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: my-gemini-account
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-gemini-account
    display_name: "my-gemini-account"
    type: gemini
    config:
      auth:
        type: basic
        headers:
        - name: x-goog-api-key
          value: !secret {source: !env GEMINI_API_KEY}
{% endentity_examples %}

{:.info}
> `ai-quickstart` references the {{site.ai_gateway}} created by the quickstart script in the prerequisites above, instead of creating a new one.

The AI Model Provider uses the following settings:

* `type: gemini`: Specifies that this provider connects to the Gemini service using Gemini's standard API format.
* `name: my-gemini-account`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your Gemini API key. `value: !secret {source: !env GEMINI_API_KEY}` loads the value from your environment at apply time instead of embedding it in the YAML, and `kongctl` redacts it in plan and diff output. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

## Create an AI Policy entity

Create an [AI Policy](/ai-gateway/entities/ai-policy/) entity using the [AI Request Transformer Policy](/ai-gateway/policies/ai-request-transformer/) to remove extra fields that Gemini's API does not support.

{% entity_examples %}
ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
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

The AI Policy uses the following settings:

* `type: request-transformer-advanced`: Modifies requests before {{site.ai_gateway}} forwards them upstream.
*  `config.remove.headers`: Removes the `anthropic-beta`, `authorization`, and `x-api-key` headers.
*  `config.remove.querystring`: Removes the `beta` query string parameter.
*  `config.remove.body`: Removes the `output_config`, `context_management`, `mcp_servers`, `container`, `service_tier`, and `reasoning_effort` body fields.

{:.info}
> Don't strip `model`: {{site.ai_gateway}} uses that field to select the target, and removing it breaks routing.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: my-gemini-account
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-gemini-account
    display_name: "my-gemini-account"
    type: gemini
    config:
      auth:
        type: basic
        headers:
        - name: x-goog-api-key
          value: !secret {source: !env GEMINI_API_KEY}
ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
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
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
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
          body_param: model
          values:
            - my-claude-gemini
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

The AI Model uses the following settings:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-claude-gemini`: A unique identifier for this model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format, matching what {{ site.claude_code }} sends natively, even though the upstream model is Gemini.
* `config.route.paths: [/]`: Configures the custom base path where this model's routes will be accessible. Setting this to a unique value avoids clashes when you have multiple AI Models.
* `capabilities: [generate]`: Enables the text generation capability. For a model using the `anthropic` format, the `generate` capability creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with your base path, clients send requests to `/v1/messages`.
* `targets`: Specifies which upstream AI Model Provider model to route requests to. Here, `provider: !ref my-gemini-account#name` references the AI Model Provider we created earlier, and `name: gemini-2.5-flash` specifies which Gemini model to call upstream.
* `policies: [!ref strip-claude-beta-info#name]`: Attaches the AI Policy created earlier so it applies to every request to this AI Model.

## Run {{ site.claude_code }}

{{ site.claude_code }}'s experimental beta features send fields that Gemini rejects even with the AI Policy in place. Disable them, then start a session pointed at your local {{site.ai_gateway}} endpoint:

<!-- vale off -->
{% validation claude-code %}
prompt: Tell me about the Madrid Skylitzes manuscript.
model: my-claude-gemini
disable_experimental_betas: true
base_url: http://localhost:8000/
{% endvalidation %}
<!-- vale on -->

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
