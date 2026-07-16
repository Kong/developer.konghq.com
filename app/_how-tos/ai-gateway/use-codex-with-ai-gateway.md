---
title: Route OpenAI Codex CLI traffic through {{site.ai_gateway}}
permalink: /ai-gateway/use-codex-with-ai-gateway/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

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
    - title: OpenAI
      icon_url: /assets/icons/openai.svg
      content: |
        Get an API key from [platform.openai.com/api-keys](https://platform.openai.com/api-keys) and export it as the **full `Authorization` header value** (including the `Bearer ` prefix):

        ```sh
        export OPENAI_AUTH_HEADER="Bearer your_api_key"
        ```
    - title: Codex CLI
      icon_url: /assets/icons/openai.svg
      content: |
        Install Node.js 18+ (verify with `node --version`), then install the OpenAI Codex CLI:

        ```sh
        npm install -g @openai/codex
        ```

---

## Create an AI Model Provider and AI Model

Codex speaks OpenAI's native format and calls the [Responses API](https://platform.openai.com/docs/api-reference/responses), so no request-transformer policy is needed. Create both the [AI Model Provider](/ai-gateway/entities/ai-model-provider/) and the [AI Model](/ai-gateway/entities/ai-model/) in a single `kongctl` apply command so the model can reference the provider:

```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl:
    namespace: codex-openai

ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: ai-quickstart

    model_providers:
      - ref: openai
        name: openai
        type: openai
        display_name: "OpenAI"
        config:
          auth:
            type: basic
            headers:
              - name: Authorization
                value: !env OPENAI_AUTH_HEADER

    models:
      - ref: codex-openai
        name: codex-openai
        display_name: "Codex - OpenAI Responses API"
        type: model
        enabled: true
        formats: [{ type: openai }]
        config:
          route: { paths: [/codex], methods: [GET, POST] }
          model: { alias: gpt-5.4, name_header: true }
        capabilities: [agentic]
        targets:
          - name: gpt-5.4
            provider: openai
            config:
              type: openai
              upstream_url: "https://api.openai.com/v1/responses"
EOF
```

In this example:

 * `type: openai`: Connects to the OpenAI API.
 * `capabilities: [agentic]`: Routes requests to the OpenAI Responses API, which the Codex CLI uses.
 * `formats: [{ type: openai }]`: Accepts OpenAI-format requests.
 * `config.model.alias: gpt-5.4`: The model name the Codex CLI sends in each request.
 * `route.paths: [/codex]`: The base path Codex points at; the Responses API is served at `/codex/responses`.

## Verify the AI Model

Before starting Codex, confirm the route works by sending a Responses API request directly (expect `200`):

```sh
curl -sS http://localhost:8000/codex/responses \
  -H 'Content-Type: application/json' \
  -d '{"model":"gpt-5.4","input":"Reply with just: ok","max_output_tokens":16}'
```

{% warning %}
If you are a new Codex user, you must Initialise the tool first by running `codex` and following the steps provided.
{% endwarning %}
## Point Codex CLI at {{site.ai_gateway}}

Open a new terminal and set `OPENAI_BASE_URL` to the local {{site.ai_gateway}} endpoint. The Codex CLI requires `OPENAI_API_KEY` to be set even though the real key lives on the gateway, so a placeholder is fine:

```sh
export OPENAI_API_KEY=sk-placeholder
export OPENAI_BASE_URL=http://localhost:8000/codex
```

## Start and use Codex CLI

Run a simple command to confirm traffic flows through {{site.ai_gateway}} to OpenAI:

```sh
codex exec --model gpt-5.4 "Hello"
```

When prompted for network access, select **Yes, proceed**. Codex routes the request through {{site.ai_gateway}} to the OpenAI Responses API and returns the model's response, giving you monitoring and control over all Codex LLM traffic.