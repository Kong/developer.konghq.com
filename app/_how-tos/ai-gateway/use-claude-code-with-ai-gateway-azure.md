---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Azure
permalink: /ai-gateway/use-claude-code-with-ai-gateway-azure/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic to a Claude model hosted on Azure AI Foundry

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

prereqs:
  konnect:
    - name: KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE
      value: 2m
  inline:
    - title: Azure AI Foundry
      include_content: md/ai-gateway/v2/prereqs/azure-ai-claude
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

min_version:
  ai-gateway: '2.0'

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} for a Claude model hosted on Azure AI Foundry?
  a: Install {{ site.claude_code }}, create an AI Model Provider for your Azure AI Foundry Claude deployment, add a policy to strip Anthropic-only request fields Azure doesn't support, create an AI Model that targets it, then point {{ site.claude_code }}'s `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all LLM requests pass through the gateway for monitoring and control.

---

## Create an AI Model Provider entity

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection and store your authentication credentials:

{% entity_examples %}
ai_gateway_model_providers:
  - ref: azure-claude
    name: azure-claude
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: anthropic
    config:
      auth:
        type: basic
        headers:
          - name: x-api-key
            value: !env AZURE_AI_FOUNDRY_TOKEN
{% endentity_examples %}

{:.info}
> `ai-quickstart` references the {{site.ai_gateway}} created by the quickstart script in the prerequisites above, instead of creating a new one.

The AI Model Provider uses the following settings:

* `type: anthropic`: Specifies that this provider speaks Anthropic's native Messages API format. Azure AI Foundry serves Claude models through this same native API, so don't use `type: azure`.
* `config.auth.headers[0].value: !env AZURE_AI_FOUNDRY_TOKEN`: Loads the API key from your environment at apply time so it is not embedded in the config.

## Create AI Policy and AI Model entities

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use.

Create an [AI Policy](/ai-gateway/entities/ai-policy/) entity using [request transformer](/ai-gateway/policies/ai-request-transformer/) to remove extra fields that Azure AI Foundry's Claude API does not support. 

{% entity_examples %}
ai_gateway_policies:
  - ref: claude-code-compat
    name: claude-code-compat
    display_name: claude-code-compat
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: request-transformer-advanced
    enabled: true
    global: false
    config:
      add:
        headers:
          - "anthropic-version:2023-06-01"
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
ai_gateway_models:
  - ref: claude-code-azure-sonnet
    display_name: claude-code-azure-sonnet
    name: claude-code-azure-sonnet
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    type: model
    enabled: true
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - claude-code-azure-sonnet
    capabilities:
       - generate
    policies:
      - !ref claude-code-compat#name
    targets:
      - name: claude-sonnet-4-6
        provider: azure-claude
        config:
          type: anthropic
          upstream_url: !env AZURE_AI_FOUNDRY_UPSTREAM_URL
{% endentity_examples %}

The AI Policy uses the following settings:

* `type: request-transformer-advanced`: Modifies requests before {{site.ai_gateway}} forwards them upstream.
* `config.add.headers`: Adds the `anthropic-version` header Azure AI Foundry's native Anthropic endpoint requires. {{ site.claude_code }} doesn't send this header itself, and Foundry rejects requests without it with a `400`.
* `config.remove.headers` / `config.remove.querystring` / `config.remove.body`: Strips Anthropic-beta-only fields — the `anthropic-beta` header, `beta` query string, and body fields like `mcp_servers` and `container` — that {{ site.claude_code }} sends but that Azure AI Foundry's Claude deployment doesn't support.
* `name: claude-code-compat`: The identifier you use to attach the policy.
* `targets.name:`: The name of your own Claude deployment in Azure AI Foundry

{:.info}
> {{ site.claude_code }} beta features vary by version and may add other incompatible fields over time. If you still see a `400` error mentioning an unexpected field after applying this Policy, add that field to the appropriate `remove` list and re-apply.

The AI Model uses the following settings:

* `name`/`display_name: claude-code-azure-sonnet`: The identifier you pass to `claude --model`. {{ site.claude_code }} uses this, not the upstream target name, to select the model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format, matching what {{ site.claude_code }} sends natively.
* `config.route.paths: [/]`: Configures the base path where this model's routes are accessible.
* `capabilities: [generate]`: Enables text generation. For a model using the `anthropic` format, `generate` creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with your base path, clients send requests to `/v1/messages`.
* `policies`: Attaches the `claude-code-compat` policy created in the previous step, so its header and body transformations apply to every request sent through this model.
* `targets`: Specifies which upstream model to route requests to. `provider: azure-claude` references the AI Provider created earlier, and `name: claude-sonnet-4-6` must match the name of your Claude deployment in Azure AI Foundry.
* `targets[0].config.upstream_url`: The base Azure AI Foundry endpoint from the prerequisites, ending at `/anthropic`. {{site.ai_gateway}} appends the rest of the Anthropic Messages API path automatically.

## Run {{ site.claude_code }}

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

<!-- vale off -->
{% validation claude-code %}
prompt: Tell me about the Madrid Skylitzes manuscript.
model: claude-code-azure-sonnet
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