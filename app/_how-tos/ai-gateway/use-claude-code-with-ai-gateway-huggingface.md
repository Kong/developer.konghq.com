---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Hugging Face
content_type: how_to
permalink: /ai-gateway/use-claude-code-with-ai-gateway-huggingface/

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic to a Hugging Face model

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

prereqs:
  inline:
    - title: Hugging Face
      content: |
        1. Create a [Hugging Face access token](https://huggingface.co/settings/tokens) with inference permissions.
        1. Export the token as a bearer header value:

           ```bash
           export HUGGINGFACE_AUTH_HEADER='Bearer YOUR_HUGGINGFACE_TOKEN'
           ```
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - huggingface

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} against a Hugging Face model?
  a: Create an AI Provider entity to store your Hugging Face token, create an AI Policy that strips fields Claude CLI sends that Hugging Face's API rejects, create an AI Model entity with an Anthropic-compatible format that routes to Hugging Face through that provider, then point Claude CLI's `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all LLM requests pass through the gateway for monitoring and control.

---

## Create an AI Model Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection and store your authentication credentials:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: my-huggingface-account
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-huggingface-account
    display_name: "Hugging Face"
    type: huggingface
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env HUGGINGFACE_AUTH_HEADER}
{% endentity_examples %}

{:.info}
> `ai-quickstart` references the {{site.ai_gateway}} created by the quickstart script in the prerequisites above, instead of creating a new one.

The AI Model Provider uses the following settings:

* `type: huggingface`: Specifies that this provider speaks Hugging Face's Messages API format.
* `config.auth.headers[0].value: !secret {source: !env HUGGINGFACE_AUTH_HEADER}`: Loads the API key from your environment at apply time so it is not embedded in the config, and `kongctl` redacts it in plan and diff output.

## Create an AI Policy entity

Create an [AI Policy](/ai-gateway/entities/ai-policy/) entity using [request transformer](/ai-gateway/policies/ai-request-transformer/) to remove extra fields that  Hugging Face's API does not support. 

{% entity_examples %}
ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: strip-claude-beta-info
    display_name: "Strip Claude beta info"
    type: request-transformer-advanced
    config:
      remove:
        headers:
          - anthropic-beta
        querystring:
          - beta
        body:
          - output_config
          - context_management
          - mcp_servers
          - container
          - service_tier
{% endentity_examples %}

{:.info}
> {{ site.claude_code }} beta features vary by version and may add other incompatible fields over time. If you still see a `400` error mentioning an unexpected field after applying this Policy, add that field to the appropriate `remove` list and re-apply.

The AI Policy uses the following settings:

* `type: request-transformer-advanced`: Modifies requests before {{site.ai_gateway}} forwards them upstream.
*  `config.remove.headers`: Removes the `anthropic-beta` header.
*  `config.remove.querystring`: Removes the `beta` query string parameter.
*  `config.remove.body`: Removes the `output_config`, `context_management`, `mcp_servers`, `container`, and `service_tier`body fields.

## Create an AI Model entity

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use:

{:.info}
> `formats: [type: anthropic]` accepts requests in Anthropic format even though the upstream is Hugging Face:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: my-huggingface-account
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-huggingface-account
    display_name: "Hugging Face"
    type: huggingface
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env HUGGINGFACE_AUTH_HEADER}
ai_gateway_policies:
  - ref: strip-claude-beta-info
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: strip-claude-beta-info
    display_name: "Strip Claude beta info"
    type: request-transformer-advanced
    config:
      remove:
        headers:
          - anthropic-beta
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
  - ref: my-huggingface
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-huggingface
    display_name: "my-huggingface"
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
            - my-huggingface
    targets:
      - name: deepseek-ai/DeepSeek-V4-Pro-0813
        provider: !ref my-huggingface-account#name
        config:
          type: huggingface
    policies:
      - !ref strip-claude-beta-info#name
    capabilities:
      - generate
{% endentity_examples %}

The AI Model uses the following settings:

* `name`/`display_name: my-huggingface`: The identifier you pass to `claude --model`. {{ site.claude_code }} uses this, not the upstream target name, to select the model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format, matching what {{ site.claude_code }} sends natively.
* `config.route.paths: [/]`: Configures the base path where this model's routes are accessible.
* `capabilities: [generate]`: Enables text generation. For a model using the `anthropic` format, `generate` creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with your base path, clients send requests to `/v1/messages`.
* `policies`: Attaches the `strip-claude-beta-info` policy created in the previous step, so its header and body transformations apply to every request sent through this model.

## Run {{ site.claude_code }}

{{ site.claude_code }}'s experimental beta features send fields that Hugging Face rejects even with the AI Policy in place. Disable them, then start a session pointed at your local {{site.ai_gateway}} endpoint:

<!-- vale off -->
{% validation claude-code %}
prompt: Tell me about the Madrid Skylitzes manuscript.
model: my-huggingface
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