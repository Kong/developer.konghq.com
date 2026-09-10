---
title: Route OpenAI Codex CLI traffic through {{site.ai_gateway}}
permalink: /ai-gateway/use-codex-with-ai-gateway/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: OpenAI provider
    url: /ai-gateway/ai-providers/openai/
  - text: AI Model Provider
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Model
    url: /ai-gateway/entities/ai-model/

description: Configure {{site.ai_gateway}} to proxy OpenAI Codex CLI traffic through the OpenAI Responses API.

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
  - openai

tldr:
  q: How do I run OpenAI Codex CLI through {{site.ai_gateway}}?
  a: Create an AI Model Provider for OpenAI and an AI Model with the `agentic` capability that targets the OpenAI Responses API, then point Codex CLI's `OPENAI_BASE_URL` at your local {{site.ai_gateway}} endpoint so all requests pass through the gateway for monitoring and control.

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl
      icon_url: /assets/icons/openai.svg
    - title: Codex CLI
      icon_url: /assets/icons/openai.svg
      content: |
        Install Node.js 18+ (verify with `node --version`), then install the OpenAI Codex CLI:

        ```sh
        npm install -g @openai/codex
        ```

---

## Create an AI Model Provider and AI Model

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection and store your authentication credentials.

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use.

{% entity_examples %}
ai_gateway_model_providers:
  - ref: openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: openai
    type: openai
    display_name: "OpenAI"
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_models:
  - ref: codex-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: codex-openai
    display_name: "Codex - OpenAI Responses API"
    type: model
    enabled: true
    formats: [{ type: openai }]
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - codex-openai
    capabilities: [agentic]
    targets:
      - name: gpt-5.4
        provider: openai
        config:
          type: openai
          upstream_url: "https://api.openai.com/v1/responses"
{% endentity_examples %}

In this example, we're setting up the AI Model Provider with:

* `type: openai`: Specifies that this provider connects using OpenAI's standard API format.
* `config.auth.headers[0].value: !secret {source: !env OPENAI_AUTH_HEADER}`: Loads the API key from your environment at apply time so it is not embedded in the config, and `kongctl` redacts it in plan and diff output.

In this example, we're setting up the AI Model with:

* `capabilities: [agentic]`: Routes requests to the OpenAI Responses API, which the Codex CLI uses.
* `formats: [{ type: openai }]`: Accepts OpenAI-format requests.
* `config.route.model: { body_param: model, values: [codex-openai] }`: The model name the Codex CLI sends in each request.
* `route.paths: [/]`: The base path Codex points at. The Responses API is served at `/responses`.

## Start and use Codex CLI

Run a simple command to confirm traffic flows through {{site.ai_gateway}} to OpenAI:

<!--vale off-->
{% validation codex %}
model: codex-openai
model_provider: my-gateway
model_provider_name: AI Quickstart
model_provider_base_url: http://localhost:8000/
model_provider_env_key: OPENAI_API_KEY
model_provider_wire_api: responses
prompt: Tell me about the Madrid Skylitzes manuscript.
{% endvalidation %}
<!--vale on-->

When prompted for network access, select **Yes, proceed**. Codex routes the request through {{site.ai_gateway}} to the OpenAI Responses API and returns the model's response, giving you monitoring and control over all Codex LLM traffic.

{:.info}
> The Codex CLI requires `OPENAI_API_KEY` to be set even though the real key lives on the {{site.ai_gateway}}, so setting a placeholder is fine. You may be prompted to confirm this in the UI.
