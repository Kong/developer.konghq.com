---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
content_type: how_to
permalink: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

prereqs:
  inline:
    - title: Anthropic
      icon_url: /assets/icons/anthropic.svg
      include_content: md/ai-gateway/v2/prereqs/anthropic
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - anthropic

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}}?
  a: Install {{ site.claude_code }}, create an AI Model Provider for Anthropic and an AI Model that targets it, then point {{ site.claude_code }}'s `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all LLM requests pass through the gateway for monitoring and control.

---

## Create an AI Model Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection and store your authentication credentials:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: generic-anthropic
    ai_gateway: !lookup name:ai-quickstart
    name: generic-anthropic
    display_name: "generic-anthropic"
    type: anthropic
    config:
      auth:
        type: basic
        headers:
          - name: x-api-key
            value: !env ANTHROPIC_API_KEY
{% endentity_examples %}

{:.info}
> `ai-quickstart` references the {{site.ai_gateway}} created by the quickstart script in the prerequisites above, instead of creating a new one.

The AI Model Provider uses the following settings:

* `type: anthropic`: Specifies that this provider connects to the Anthropic service using Anthropic's standard API format.
* `name: generic-anthropic`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth.headers[0].value: !env ANTHROPIC_API_KEY`: Loads the API key from your environment at apply time so it is not embedded in the config.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use:

{% entity_examples %}
ai_gateway_models:
  - ref: my-claude
    ai_gateway: !lookup name:ai-quickstart
    name: my-claude
    display_name: "my-claude"
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
            - my-claude
    targets:
      - name: claude-opus-4-8
        provider: generic-anthropic
        config:
          type: anthropic
    policies: []
    capabilities:
      - generate
{% endentity_examples %}

The AI Model uses the following settings:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-claude`: A unique identifier for this model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format.
* `config.route.paths: [/]`: Configures the custom base path where this model's routes will be accessible. Setting this to a unique value avoids clashes when you have multiple AI Models.
* `capabilities: [generate]`: Enables the text generation capability. For a model using the `anthropic` format, the `generate` capability creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with your base path, clients send requests to `/messages`.
* `targets`: Specifies which upstream AI Model Provider model to route requests to. Here, `provider: generic-anthropic` references the AI Model Provider we created earlier, and `name: claude-opus-4-8` specifies which Anthropic model to call upstream.

## Verify traffic through {{site.ai_gateway}}

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/ claude --model 'my-claude'
```

Ask a question to confirm that requests reach {{site.ai_gateway}}.

{% validation claude-code %}
prompt: Tell me about the Madrid Skylitzes manuscript.
model: my-claude
{% endvalidation %}


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