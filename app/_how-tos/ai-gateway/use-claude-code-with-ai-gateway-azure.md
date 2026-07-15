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

min_version:
  ai-gateway: '2.0'

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} for a Claude model hosted on Azure AI Foundry?
  a: Install {{ site.claude_code }}, create an AI Model Provider for your Azure AI Foundry Claude deployment, add a policy to strip Anthropic-only request fields Azure doesn't support, create an AI Model that targets it, then point {{ site.claude_code }}'s `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all LLM requests pass through the gateway for monitoring and control.

---

## Create an AI Model Provider entity

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl: { namespace: ai-gateway-get-started }

ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: ai-quickstart

ai_gateway_model_providers:
  - ref: azure-claude
    name: azure-claude
    ai_gateway: ai-quickstart
    type: anthropic
    config:
      auth:
        type: basic
        headers:
          - name: x-api-key
            value: !env AZURE_AI_FOUNDRY_TOKEN
EOF
```

{:.info}
> `ai-quickstart` references the {{site.ai_gateway}} created by the quickstart script in the prerequisites above, instead of creating a new one.

The AI Model Provider uses:

 * `type: anthropic`: Specifies that this provider speaks Anthropic's native Messages API format. Azure AI Foundry serves Claude models through this same native API, so don't use `type: azure`.
 * `config.auth.headers[0].value: !env AZURE_AI_FOUNDRY_TOKEN`: Loads the API key from your environment at apply time so it is not embedded in the config.

## Create an AI Policy and AI Model

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: ai-gateway-get-started

ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: "ai-quickstart"

ai_gateway_policies:
  - ref: claude-code-compat
    name: claude-code-compat
    ai_gateway: ai-quickstart
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
    ai_gateway: ai-quickstart
    type: model
    enabled: true
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
      model:
        name_header: true
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

EOF
```
{:.collapsible}

We create an [AI Policy](/ai-gateway/entities/ai-policy/) entity using [request transformer](/ai-gateway/policies/ai-request-transformer/) to remove extra fields that Azure AI Foundry's Claude endpoint does not support. 

This uses the following settings:

* `type: request-transformer-advanced`: Modifies requests before {{site.ai_gateway}} forwards them upstream.
* `config.add.headers`: Adds the `anthropic-version` header Azure AI Foundry's native Anthropic endpoint requires. {{ site.claude_code }} doesn't send this header itself, and Foundry rejects requests without it with a `400`.
* `config.remove.headers` / `config.remove.querystring` / `config.remove.body`: Strips Anthropic-beta-only fields — the `anthropic-beta` header, `beta` query string, and body fields like `mcp_servers` and `container` — that {{ site.claude_code }} sends but that Azure AI Foundry's Claude deployment doesn't support.
* `name: claude-code-compat`: The identifier you use to attach the policy.

{:.info}
> Replace `claude-sonnet-4-6` with the name of your own Claude deployment in Azure AI Foundry.

The AI Model uses:

* `name`/`display_name: claude-code-azure-sonnet`: The identifier you pass to `claude --model`. {{ site.claude_code }} uses this, not the upstream target name, to select the model.
* `formats: [type: anthropic]`: Declares that this model accepts requests in Anthropic-compatible format, matching what {{ site.claude_code }} sends natively.
* `config.route.paths: [/]`: Configures the base path where this model's routes are accessible.
* `config.model.name_header: true`: Lets {{ site.claude_code }} select this model by sending its `name` in the request, instead of requiring a separate `alias`.
* `capabilities: [generate]`: Enables text generation. For a model using the `anthropic` format, `generate` creates a `/messages` endpoint matching Anthropic's native Messages API, so combined with your base path, clients send requests to `/v1/messages`.
* `policies`: Attaches the `claude-code-compat` policy created in the previous step, so its header and body transformations apply to every request sent through this model.
* `targets`: Specifies which upstream model to route requests to. `provider: azure-claude` references the AI Provider created earlier, and `name: claude-sonnet-4-6` must match the name of your Claude deployment in Azure AI Foundry.
* `targets[0].config.upstream_url`: The base Azure AI Foundry endpoint from the prerequisites, ending at `/anthropic`. {{site.ai_gateway}} appends the rest of the Anthropic Messages API path automatically.

## Verify traffic through {{site.ai_gateway}}

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/ claude --model 'claude-code-azure-sonnet'
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
Tell me about Vienna Oribasius manuscript.
```

{{ site.claude_code }} might prompt you to approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request:

```text
The "Vienna Oribasius manuscript" refers to a famous illustrated medical
codex that preserves the works of Oribasius of Pergamon, a noted Greek
physician who lived in the 4th century CE. Oribasius was a compiler of
earlier medical knowledge, and his writings form an important link in the
transmission of Greco-Roman medical science to the Byzantine, Islamic, and
later European worlds.
```
{:.no-copy-code}