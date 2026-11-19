---
title: GitHub Copilot BYOK Custom Endpoint
description: Route GitHub Copilot chat and agent requests from VS Code through {{site.ai_gateway_name}}, with a per-developer API key, request normalization, and a token budget for each developer.
url: "/cookbooks/github-copilot-byok/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
works_on:
  - konnect
min_version:
  ai-gateway: '2.0'
categories:
  - llm
  - access-control
featured: false
popular: false
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script. The two `-e` settings raise the data plane's request body buffer and limit to 16 MB, so the large request bodies that Copilot sends (conversation history, tool definitions, file contents) stay in memory instead of being buffered to disk:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='github-copilot-byok-recipe'
           curl -Ls https://get.konghq.com/ai | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE=16m \
               -e KONG_NGINX_HTTP_CLIENT_MAX_BODY_SIZE=16m
           ```

           This provisions an {{site.ai_gateway}} named `github-copilot-byok-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: VS Code and GitHub Copilot
      content: |
        This tutorial adds a custom endpoint model to GitHub Copilot chat in VS Code. VS Code calls this feature [bring your own language model key (BYOK)](https://code.visualstudio.com/docs/agent-customization/language-models#_bring-your-own-language-model-key).

        1. Install VS Code and set up GitHub Copilot from the [VS Code setup guide](https://code.visualstudio.com/docs/setup/copilot).
        1. If you use Copilot Business or Copilot Enterprise, ask your organization administrator to enable the **Bring Your Own Language Model Key in VS Code** policy in the Copilot policy settings on GitHub.com. Without this policy, you can't add your own models ([GitHub documentation](https://docs.github.com/en/copilot/concepts/models/bring-your-own-key)).
    - title: AI Credentials
      content: |
        Pick the provider you want to route to and export its credentials. The provider's tab in [Apply the Kong configuration](#apply-the-kong-configuration) reads these variables.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
        {% endnavtab %}
        {% navtab "Azure OpenAI" %}
        Azure binds each deployment to one model, and the deployment ID selects the upstream model ([Azure OpenAI REST API reference](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)).

        1. [Create an Azure OpenAI resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI).
        1. Deploy a chat model in the resource, for example `gpt-4o`.
        1. Export your credentials. `AZURE_DEPLOYMENT_ID` is the deployment name that you chose in the Azure portal. Use the current API version from the Azure OpenAI REST API reference:

           ```sh
           export AZURE_API_KEY='your-azure-api-key'
           export AZURE_INSTANCE='your-instance-name'
           export AZURE_DEPLOYMENT_ID='your-deployment-id'
           export AZURE_API_VERSION='YOUR-API-VERSION'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        1. Get an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Export your AWS credentials and region:

           ```sh
           export AWS_ACCESS_KEY_ID='your-access-key'
           export AWS_SECRET_ACCESS_KEY='your-secret-key'
           export AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% endnavtabs %}
overview: |
  Put {{site.ai_gateway_name}} between GitHub Copilot chat in VS Code and your LLM provider, so that each developer uses their own revocable API key and the provider key stays in {{site.ai_gateway}}. You'll set up:

  * A custom endpoint model in VS Code that sends Copilot chat and agent requests to {{site.ai_gateway}}
  * An API key and a token budget for each developer
  * A model alias that decouples the model name in VS Code from the upstream model
  * A {{site.konnect_short_name}} dashboard for Copilot usage by developer

  This cookbook covers Copilot chat and agent requests. Inline suggestions (code completions) don't use custom endpoint models, so they don't go through {{site.ai_gateway}} ([VS Code documentation](https://code.visualstudio.com/docs/agent-customization/language-models#_bring-your-own-language-model-key)).
---

## What this cookbook solves

With bring your own key (BYOK) in VS Code, each developer configures a provider API key in their own editor, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each developer holds a copy of the provider API key, and VS Code sends requests directly to the provider. A leaked key means rotating it on every machine."
    solution: "The AI Model Provider keeps the provider credentials in Kong. Each developer holds only their own AI Consumer key, which you revoke without touching the others."
  - problem: "GitHub reports BYOK usage from client telemetry only, so platform teams can't see reliable usage and cost for each developer."
    solution: "The Key Auth AI Auth Strategy maps each key to an AI Consumer. {{site.konnect_short_name}} shows tokens and cost for each AI Consumer, and the cookbook's dashboard groups them by developer."
  - problem: "Nothing limits how many tokens one developer spends. Agent sessions with large workspace context use up the budget fast."
    solution: "The AI Rate Limiting Advanced Policy gives each AI Consumer a token budget and returns `429` when the budget runs out."
  - problem: "VS Code sends the key as `Authorization: Bearer`, and the request body can carry parameters that a model doesn't support, for example `temperature` for the newest OpenAI models."
    solution: "A global Pre-Function Policy copies the Bearer token to the `apikey` header before authentication and removes `temperature` from the request body."
  - problem: "Each developer's `chatLanguageModels.json` names the upstream model, so changing the model means editing every developer's settings."
    solution: "The AI Model answers to an alias. You change the upstream model in Kong, and developers keep the same model ID in VS Code."
{% endtable %}

## Try it out

Apply the configuration, create the usage dashboard, add Kong as a custom endpoint model in VS Code, then use Copilot chat to test authentication, the model alias, and the token budget.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your provider's credentials, a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy, a Key Auth AI Auth Strategy, two AI Consumers (`copilot-developer-alice` and `copilot-developer-bob`) with API keys, an [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy, and an AI Model on `/github-copilot`. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Generate an API key for each of the two developers. Each developer enters their key in VS Code. The credential's `api_key` field is write-only, so its value must come from an environment variable:

```bash
export COPILOT_KEY_ALICE="$(openssl rand -hex 24)"
export COPILOT_KEY_BOB="$(openssl rand -hex 24)"
```

Export the model alias. VS Code sends this value as the `model` field, and the AI Model answers only to this value:

```bash
export COPILOT_MODEL_ALIAS='kong-copilot'
```

Select your provider. Each tab exports `CHAT_MODEL`, the upstream model that Kong sends to the provider, then applies the configuration. Provider credentials come from the prerequisites.

{% navtabs "Providers" %}
{% navtab "OpenAI" %}

Export the model env var:

```bash
export CHAT_MODEL='gpt-4o'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: github-copilot-byok-recipe
ai_gateway_model_providers:
- ref: github-copilot-byok-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-provider
  display_name: github-copilot-byok
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: github-copilot-byok-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-auth
  display_name: github-copilot-byok key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: copilot-developer-alice
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-alice
  display_name: 'Copilot developer: Alice'
  type: api-key
  credentials:
  - ref: copilot-developer-alice-credential
    name: copilot-developer-alice-credential
    display_name: Alice's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'COPILOT_KEY_ALICE'}
- ref: copilot-developer-bob
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-bob
  display_name: 'Copilot developer: Bob'
  type: api-key
  credentials:
  - ref: copilot-developer-bob-credential
    name: copilot-developer-bob-credential
    display_name: Bob's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'COPILOT_KEY_BOB'}
ai_gateway_policies:
- ref: github-copilot-byok-normalize
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-normalize
  display_name: github-copilot-byok request normalization
  type: pre-function
  global: true
  config:
    access:
    - |
      local cjson = require "cjson.safe"

      local auth = kong.request.get_header("Authorization")
      if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
        ngx.req.set_header("apikey", string.sub(auth, 8))
      end

      local body = kong.request.get_raw_body()
      if body then
        local json = cjson.decode(body)
        if json and json.temperature ~= nil then
          json.temperature = nil
          kong.service.request.set_raw_body(cjson.encode(json))
        end
      end
- ref: github-copilot-byok-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-ratelimit
  display_name: github-copilot-byok token rate limiting
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 50000
        window_size: 60
      window_type: sliding
    identifier: consumer
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_models:
- ref: github-copilot-byok-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-model
  display_name: github-copilot-byok
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - github-copilot-byok-auth
  policies:
  - github-copilot-byok-ratelimit
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /github-copilot
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'COPILOT_MODEL_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: github-copilot-byok-provider
    config:
      type: openai
      input_cost: 0.25
      output_cost: 2.0
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Azure OpenAI" %}

Export the model env var. The deployment ID from the prerequisites selects the upstream model, so set `CHAT_MODEL` to the model of that deployment:

```bash
export CHAT_MODEL='gpt-4o'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: github-copilot-byok-recipe
ai_gateway_model_providers:
- ref: github-copilot-byok-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-provider
  display_name: github-copilot-byok
  type: azure
  config:
    auth:
      type: basic
      headers:
      - name: api-key
        value: !secret {source: !env 'AZURE_API_KEY'}
    service: azure-openai
    instance: !env 'AZURE_INSTANCE'
ai_gateway_auth_strategies:
- ref: github-copilot-byok-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-auth
  display_name: github-copilot-byok key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: copilot-developer-alice
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-alice
  display_name: 'Copilot developer: Alice'
  type: api-key
  credentials:
  - ref: copilot-developer-alice-credential
    name: copilot-developer-alice-credential
    display_name: Alice's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'COPILOT_KEY_ALICE'}
- ref: copilot-developer-bob
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-bob
  display_name: 'Copilot developer: Bob'
  type: api-key
  credentials:
  - ref: copilot-developer-bob-credential
    name: copilot-developer-bob-credential
    display_name: Bob's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'COPILOT_KEY_BOB'}
ai_gateway_policies:
- ref: github-copilot-byok-normalize
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-normalize
  display_name: github-copilot-byok request normalization
  type: pre-function
  global: true
  config:
    access:
    - |
      local cjson = require "cjson.safe"

      local auth = kong.request.get_header("Authorization")
      if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
        ngx.req.set_header("apikey", string.sub(auth, 8))
      end

      local body = kong.request.get_raw_body()
      if body then
        local json = cjson.decode(body)
        if json and json.temperature ~= nil then
          json.temperature = nil
          kong.service.request.set_raw_body(cjson.encode(json))
        end
      end
- ref: github-copilot-byok-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-ratelimit
  display_name: github-copilot-byok token rate limiting
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 50000
        window_size: 60
      window_type: sliding
    identifier: consumer
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_models:
- ref: github-copilot-byok-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-model
  display_name: github-copilot-byok
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - github-copilot-byok-auth
  policies:
  - github-copilot-byok-ratelimit
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /github-copilot
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'COPILOT_MODEL_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: github-copilot-byok-provider
    config:
      api_version: !env 'AZURE_API_VERSION'
      deployment_id: !env 'AZURE_DEPLOYMENT_ID'
      type: azure
      input_cost: 0.25
      output_cost: 2.0
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "AWS Bedrock" %}

Export the model env var. Use a Bedrock model ID that supports tool calling, because Copilot agent mode needs it:

```bash
export CHAT_MODEL='anthropic.claude-sonnet-4-5-20250929-v1:0'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: github-copilot-byok-recipe
ai_gateway_model_providers:
- ref: github-copilot-byok-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-provider
  display_name: github-copilot-byok
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: !env 'AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'AWS_SECRET_ACCESS_KEY'}
ai_gateway_auth_strategies:
- ref: github-copilot-byok-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-auth
  display_name: github-copilot-byok key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: copilot-developer-alice
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-alice
  display_name: 'Copilot developer: Alice'
  type: api-key
  credentials:
  - ref: copilot-developer-alice-credential
    name: copilot-developer-alice-credential
    display_name: Alice's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'COPILOT_KEY_ALICE'}
- ref: copilot-developer-bob
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: copilot-developer-bob
  display_name: 'Copilot developer: Bob'
  type: api-key
  credentials:
  - ref: copilot-developer-bob-credential
    name: copilot-developer-bob-credential
    display_name: Bob's Copilot API key
    type: api-key
    api_key: !secret {source: !env 'COPILOT_KEY_BOB'}
ai_gateway_policies:
- ref: github-copilot-byok-normalize
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-normalize
  display_name: github-copilot-byok request normalization
  type: pre-function
  global: true
  config:
    access:
    - |
      local cjson = require "cjson.safe"

      local auth = kong.request.get_header("Authorization")
      if auth and string.sub(string.lower(auth), 1, 7) == "bearer " then
        ngx.req.set_header("apikey", string.sub(auth, 8))
      end

      local body = kong.request.get_raw_body()
      if body then
        local json = cjson.decode(body)
        if json and json.temperature ~= nil then
          json.temperature = nil
          kong.service.request.set_raw_body(cjson.encode(json))
        end
      end
- ref: github-copilot-byok-ratelimit
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-ratelimit
  display_name: github-copilot-byok token rate limiting
  type: ai-rate-limiting-advanced
  config:
    policies:
    - limits:
      - limit: 50000
        window_size: 60
      window_type: sliding
    identifier: consumer
    tokens_count_strategy: total_tokens
    strategy: local
ai_gateway_models:
- ref: github-copilot-byok-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: github-copilot-byok-model
  display_name: github-copilot-byok
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - github-copilot-byok-auth
  policies:
  - github-copilot-byok-ratelimit
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /github-copilot
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
      model:
        body_param: model
        values:
        - !env 'COPILOT_MODEL_ALIAS'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: github-copilot-byok-provider
    config:
      region: !env 'AWS_REGION'
      type: bedrock
      input_cost: 0.25
      output_cost: 2.0
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

### Create the Copilot Usage dashboard

The dashboard shows cost, token usage, request volume, model mix, usage for each developer (AI Consumer), and latency for Copilot traffic. It's an organization-level resource, so the command reuses a dashboard with the `github-copilot-byok-recipe` label if one exists.

Create the dashboard definition:

```bash
cat <<'EOF' > copilot-usage-dashboard.json
{
  "name": "Copilot Usage",
  "definition": {
    "tiles": [
      {
        "id": "c0f1ee01-0000-4000-8000-000000000001",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 0, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total cost ($)" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["cost"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000002",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 2, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total tokens" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000003",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 1 }, "position": { "col": 4, "row": 0 } },
        "definition": {
          "chart": { "type": "single_value", "chart_title": "Total Copilot requests" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": []
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000004",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 0, "row": 1 } },
        "definition": {
          "chart": { "type": "top_n", "chart_title": "Top Copilot models by usage" },
          "query": {
            "limit": 10,
            "filters": [],
            "metrics": ["total_tokens", "ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000005",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 3, "row": 1 } },
        "definition": {
          "chart": { "type": "timeseries_line", "stacked": false, "chart_title": "Model usage trend (top 5)" },
          "query": {
            "limit": 5,
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000006",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 0, "row": 3 } },
        "definition": {
          "chart": { "type": "donut", "chart_title": "Copilot health check" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["status_code_grouped"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000007",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 2, "row": 3 } },
        "definition": {
          "chart": { "type": "donut", "chart_title": "Copilot provider usage" },
          "query": {
            "filters": [
              { "field": "ai_provider", "operator": "not_empty" },
              { "field": "ai_provider", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["ai_provider"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000008",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 4, "row": 3 } },
        "definition": {
          "chart": { "type": "timeseries_bar", "stacked": true, "chart_title": "LLM latency (avg)" },
          "query": {
            "filters": [
              { "field": "ai_request_model", "operator": "not_empty" },
              { "field": "ai_request_model", "value": ["UNSPECIFIED"], "operator": "not_in" }
            ],
            "metrics": ["llm_latency_average"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-000000000009",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 0, "row": 9 } },
        "definition": {
          "chart": { "type": "horizontal_bar", "stacked": true, "chart_title": "Copilot usage by developer (requests)" },
          "query": {
            "filters": [
              { "field": "consumer", "operator": "not_empty" }
            ],
            "metrics": ["ai_request_count"],
            "datasource": "llm_usage",
            "dimensions": ["consumer"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-00000000000a",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 3, "row": 9 } },
        "definition": {
          "chart": { "type": "vertical_bar", "stacked": true, "chart_title": "Copilot usage by developer (tokens)" },
          "query": {
            "filters": [
              { "field": "consumer", "operator": "not_empty" }
            ],
            "metrics": ["total_tokens"],
            "datasource": "llm_usage",
            "dimensions": ["consumer"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-00000000000b",
        "type": "chart",
        "layout": { "size": { "cols": 2, "rows": 2 }, "position": { "col": 0, "row": 11 } },
        "definition": {
          "chart": { "type": "vertical_bar", "stacked": true, "chart_title": "AI security report (401 / 403 / 429)" },
          "query": {
            "filters": [
              { "field": "status_code", "value": ["401", "403", "429"], "operator": "in" }
            ],
            "metrics": ["request_count"],
            "datasource": "api_usage",
            "dimensions": ["status_code", "consumer"]
          }
        }
      },
      {
        "id": "c0f1ee01-0000-4000-8000-00000000000c",
        "type": "chart",
        "layout": { "size": { "cols": 3, "rows": 2 }, "position": { "col": 2, "row": 11 } },
        "definition": {
          "chart": { "type": "timeseries_bar", "stacked": true, "chart_title": "Monthly spend trends" },
          "query": {
            "limit": 10,
            "filters": [],
            "metrics": ["cost"],
            "datasource": "llm_usage",
            "dimensions": ["ai_request_model", "time"],
            "time_range": { "type": "relative", "time_range": "30d" },
            "granularity": "daily"
          }
        }
      }
    ],
    "template_id": "AI_GATEWAY"
  },
  "labels": {
    "recipe": "github-copilot-byok-recipe"
  }
}
EOF
```
{:.collapsible}

Create the dashboard in {{site.konnect_short_name}}:

```bash
EXISTING_DASHBOARDS=$(kongctl api get "/v2/dashboards?filter%5Blabels.recipe%5D=github-copilot-byok-recipe" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.data | length')

if [ "${EXISTING_DASHBOARDS}" -gt 0 ]; then
  echo "Copilot Usage dashboard already exists. Reusing."
else
  DASHBOARD_ID=$(kongctl api post /v2/dashboards \
    -f copilot-usage-dashboard.json \
    --pat "${KONNECT_TOKEN}" -o json --jq '.id' -r)
  echo "Created Copilot Usage dashboard (id: ${DASHBOARD_ID})."
fi
```
{: data-test-step="block" .collapsible }

{:.info}
> The dashboard shows LLM traffic for the whole organization. To show only this cookbook's {{site.ai_gateway}}, add a filter in the {{site.konnect_short_name}} dashboard editor.

### Connect VS Code to Kong

VS Code sends requests for a [custom endpoint model](https://code.visualstudio.com/docs/agent-customization/language-models#_add-a-custom-endpoint-model) to any URL that speaks the OpenAI Chat Completions API. VS Code keeps the API key in its secret storage and sends it as `Authorization: Bearer <key>`.

Print Alice's key, so that you can paste it into VS Code:

```bash
printf '%s\n' "$COPILOT_KEY_ALICE"
```

Add the custom endpoint model in VS Code:

1. In the Chat view, open the model picker and select **Manage Language Models** (gear icon). You can also run **Chat: Manage Language Models** from the Command Palette.
1. Select **Add Models**, then select **Custom Endpoint**.
1. Enter `Kong` as the group name.
1. Enter a display name, and paste Alice's key as the API key.
1. Select **Chat Completions** as the API type.

VS Code opens `chatLanguageModels.json`. Update the model entry to match the following example, and keep the `apiKey` value that VS Code wrote, because it references the key in secret storage:

```json
[
  {
    "name": "Kong",
    "vendor": "customendpoint",
    "apiKey": "${input:kongApiKey}",
    "apiType": "chat-completions",
    "models": [
      {
        "id": "kong-copilot",
        "name": "Kong Copilot",
        "url": "http://localhost:8000/github-copilot/chat/completions",
        "toolCalling": true,
        "vision": false,
        "maxInputTokens": 128000,
        "maxOutputTokens": 16000
      }
    ]
  }
]
```
{:.no-copy-code}

The model fields have the following roles:

{% table %}
columns:
  - title: Field
    key: field
  - title: Purpose
    key: purpose
rows:
  - field: "`id`"
    purpose: "The model identifier that VS Code sends in the `model` field. It must equal `COPILOT_MODEL_ALIAS`."
  - field: "`url`"
    purpose: "The full endpoint URL. VS Code uses a URL that ends in `/chat/completions` as it is."
  - field: "`toolCalling`"
    purpose: "Set to `true`. VS Code shows a model in agent mode only if it supports tool calling."
  - field: "`maxInputTokens` and `maxOutputTokens`"
    purpose: "Together they define the context window that VS Code uses. Set them from your upstream model's documentation."
{% endtable %}

Save the file. If the model doesn't appear in the model picker, restart VS Code.

### Ask Copilot a question

Select **Kong Copilot** in the Chat view's model picker and send a prompt, for example:

```text
Explain what an API gateway does in one sentence.
```
{:.no-copy-code}

The answer streams into the Chat view. Kong copied the Bearer token to `apikey`, authenticated Alice's AI Consumer, matched the `kong-copilot` alias, and sent the request upstream with the provider credentials. If Copilot shows a `401` error, the key didn't reach Kong. Update the API key from the gear icon next to the **Kong** provider in the Language Models editor, and paste the key again.

### Hit the model alias boundary

The AI Model answers only to the alias. In `chatLanguageModels.json`, change `id` to another value, for example `gpt-4o`, save the file, and send a prompt. Kong finds no AI Model for that name and rejects the request before any provider call. On runtime 2.3.1, the status is `500` after about 12 seconds, with `failed the initial dns/balancer resolve for 'ai-gateway.upstream.local'` in the body.

Change `id` back to `kong-copilot`, and requests succeed again.

### Hit the rate limit

Each AI Consumer can use 50,000 tokens in a 60-second sliding window. Agent requests that carry workspace context are large, so a few prompts in quick succession use up the budget. For example, ask Copilot to summarize several files in your repository. When Alice's budget runs out, Copilot shows an error with the status:

```text
429 Too Many Requests
```
{:.no-copy-code}

Bob's AI Consumer has `identifier: consumer` on the same AI Rate Limiting Advanced Policy. Select the gear icon next to the **Kong** provider in the Language Models editor, replace the API key with the value of `COPILOT_KEY_BOB`, and send a prompt. In a test on runtime 2.3.1 from one machine, Alice and Bob shared one token counter, so Bob's request was also limited. This cookbook hasn't confirmed separate budgets for developers on different machines.

### Check the results

The Copilot sessions confirm the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Per-developer authentication"
    evidence: "Copilot answers with Alice's key and with Bob's key. Neither developer holds the provider key."
  - behavior: "Bearer token accepted"
    evidence: "VS Code sends `Authorization: Bearer`, and the Key Auth AI Auth Strategy still authenticates the request, because the global Pre-Function Policy copied the token to `apikey` first."
  - behavior: "Model alias"
    evidence: "Requests with `id: kong-copilot` succeed. Another `id` gets an error before any provider call."
  - behavior: "Token budget"
    evidence: "Alice gets `429 Too Many Requests` after about 50,000 tokens in a minute. Whether Bob still has his own budget depends on how Kong separates the counters (see the `identifier: consumer` row in How it works)."
  - behavior: "Usage for each developer"
    evidence: "The Copilot Usage dashboard shows requests and tokens for `copilot-developer-alice` and `copilot-developer-bob`."
{% endtable %}

To review the created entities and per-consumer usage, open the `github-copilot-byok-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu. The Copilot Usage dashboard is in **{{site.observability}} > Dashboards**.

## How it works

VS Code sends each chat or agent request to Kong with the developer's key as a Bearer token. A global Pre-Function Policy copies the token to the `apikey` header, the Key Auth AI Auth Strategy identifies the AI Consumer, the AI Model matches the alias, the AI Rate Limiting Advanced Policy checks the developer's token budget, and Kong forwards the request with the provider credentials.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant VS as VS Code
    participant K as Kong AI Gateway
    participant L as LLM Provider

    VS->>K: POST /github-copilot/chat/completions (Authorization Bearer key, model kong-copilot)
    activate K
    K->>K: Global Pre-Function Policy copies the Bearer token to apikey and removes temperature
    K->>K: Key Auth AI Auth Strategy identifies the AI Consumer (else 401)
    K->>K: AI Model matches the alias in the model field
    K->>K: AI Rate Limiting Advanced Policy checks the token budget (else 429)
    K->>L: Request with the provider credentials and the upstream model
    activate L
    L-->>K: Response
    deactivate L
    K-->>VS: OpenAI-format response
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Pre-Function Policy

The Pre-Function Policy runs Lua code from its `config.access` list in the access phase. It's global, because a global Pre-Function Policy runs before authentication, while one listed on the AI Model runs after it ([sandboxing](/ai-gateway/sandboxing/)). The Key Auth AI Auth Strategy reads the `apikey` header, so the header must exist before authentication runs.

The following settings configure the Pre-Function Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`global: true`"
    purpose: "Runs the policy for each request on the {{site.ai_gateway}}, before authentication. If one {{site.ai_gateway}} has several global Pre-Function Policies, only the one with the highest ID takes effect."
  - setting: "`ngx.req.set_header(\"apikey\", ...)`"
    purpose: "Copies the token from an `Authorization: Bearer` header into the `apikey` header that the Key Auth AI Auth Strategy reads."
  - setting: "`kong.service.request.set_raw_body(...)`"
    purpose: "Removes `temperature` from the JSON body, so the provider uses its default. The newest OpenAI models expect Chat Completions requests without `temperature` ([OpenAI migration guide](https://developers.openai.com/api/docs/guides/latest-model)). This cookbook hasn't confirmed against a live {{site.ai_gateway}} that the AI Model forwards the changed body."
{% endtable %}

The policy uses only functions and modules that the Lua sandbox allows (`cjson.safe`, `ngx.req.set_header`, `kong.request.get_raw_body`, and `kong.service.request.set_raw_body`).

### Key Auth AI Auth Strategy and AI Consumers

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy matches the `apikey` header to an AI Consumer credential and rejects unknown keys with `401` before any provider call. The AI Consumer is the identity that the rate limit and analytics use.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumers:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey]`"
    purpose: "The header that Kong reads the key from. The Pre-Function Policy fills it from the Bearer token."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the `apikey` header before it forwards the request, so the provider never sees a developer's key."
  - setting: "`ai_gateway_consumers[].credentials`"
    purpose: "One AI Consumer for each developer, with an `api-key` credential. The `api_key` field is write-only, so it reads `COPILOT_KEY_ALICE` and `COPILOT_KEY_BOB` with `!secret`."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Usage for each AI Consumer appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Model

The AI Model Provider holds the provider credentials. The AI Model `github-copilot-byok-model` accepts OpenAI-format requests on `/github-copilot`, answers to one alias, and routes to one target that references the AI Model Provider. VS Code sends the alias, and Kong sends the target's upstream model to the provider.

The following settings configure the AI Model Provider and the AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The provider credentials. Kong adds them to each upstream request. The fields depend on the provider tab."
  - setting: "`formats: [{type: openai}]`"
    purpose: "The AI Model accepts OpenAI Chat Completions requests, which is the API type that the VS Code model uses. Kong translates the request for providers with another native format, for example Bedrock."
  - setting: "`access.auth_strategies`"
    purpose: "Each request must have a valid AI Consumer key."
  - setting: "`policies`"
    purpose: "Attaches the AI Rate Limiting Advanced Policy to the AI Model. The Pre-Function Policy isn't listed, because it's global."
  - setting: "`config.route.model`"
    purpose: "Kong reads the `model` field of the request body (`body_param: model`) and matches it against `COPILOT_MODEL_ALIAS`. An AI Model accepts one value."
  - setting: "`targets[].name`"
    purpose: "The upstream model, from `CHAT_MODEL`. Change it and re-apply to switch models without changing VS Code settings."
  - setting: "`targets[].config`"
    purpose: "The provider `type` and provider-specific target fields, for example Azure's `deployment_id` and `api_version`, or Bedrock's `region`."
  - setting: "`targets[].config.input_cost` and `output_cost`"
    purpose: "The cost for 1 million input and output tokens, which {{site.konnect_short_name}} uses for cost tracking. The values `0.25` and `2.00` are examples. Replace them with your provider's pricing for the model."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default. Copilot requests carry conversation history, tool definitions, and file contents."
  - setting: "`config.response_streaming: allow`"
    purpose: "Kong passes streamed responses to VS Code, which shows the answer as it arrives."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads for audits. The default is `false`."
{% endtable %}

### AI Rate Limiting Advanced Policy

The AI Rate Limiting Advanced Policy counts prompt and completion tokens, the unit that drives LLM cost. Each AI Consumer gets 50,000 tokens in a 60-second sliding window. When an AI Consumer uses up the budget, Kong returns `429 Too Many Requests` until the window allows requests again.

The following settings configure the AI Rate Limiting Advanced Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.policies[].limits`"
    purpose: "The token limit and the window size in seconds: `50000` and `60`."
  - setting: "`identifier: consumer`"
    purpose: "Counts usage for each AI Consumer. In a test on runtime 2.3.1, two AI Consumers that called from the same machine shared one counter. This cookbook hasn't confirmed separate budgets for developers on different machines."
  - setting: "`window_type: sliding`"
    purpose: "A sliding window, for smoother limits than the `fixed` window."
  - setting: "`tokens_count_strategy: total_tokens`"
    purpose: "Counts prompt and completion tokens. Other values count only prompt tokens, only completion tokens, or cost."
  - setting: "`strategy: local`"
    purpose: "Keeps the counters in memory on each data plane node. For several nodes, use `redis` so that the nodes share the counters."
{% endtable %}

{:.info}
> The 60-second window lets a few prompts use up the budget in this cookbook. In production, most teams use daily or monthly budgets, for example {%raw%}`limits: [{limit: 5000000, window_size: 2592000}]`{%endraw%}. Store the provider credentials and the AI Consumer keys in [AI Vaults](/ai-gateway/entities/ai-vault/) instead of environment variables.

### Response headers

Kong adds the following rate limit headers to each response:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-AI-RateLimit-Limit-minute-policy-1`"
    description: "The token limit for the 60-second window of the first entry in `config.policies`."
  - header: "`X-AI-RateLimit-Remaining-minute-policy-1`"
    description: "The tokens left in the current window. Kong rejects a request whose prompt is larger than this value with `429`."
  - header: "`X-AI-RateLimit-Reset`"
    description: "The seconds until the quota is restored."
  - header: "`X-AI-RateLimit-Retry-After`"
    description: "On a `429` response, the seconds until the AI Consumer can send requests again. There is no plain `Retry-After` header."
{% endtable %}

## Variations and next steps

You can change or extend this configuration in the following ways:

{% table %}
columns:
  - title: Variation
    key: variation
  - title: How
    key: how
rows:
  - variation: "Switch the upstream model"
    how: "Change `CHAT_MODEL` and re-apply the configuration from [Apply the Kong configuration](#apply-the-kong-configuration). Developers keep the `kong-copilot` model ID in VS Code."
  - variation: "Send the apikey header from VS Code"
    how: "Add `\"requestHeaders\": {\"apikey\": \"${apiKey}\"}` to the model in `chatLanguageModels.json`. VS Code then sends the key in `apikey` instead of `Authorization` ([custom authentication headers](https://code.visualstudio.com/docs/agent-customization/language-models#_custom-endpoint-configuration-reference)), and the Pre-Function Policy only removes `temperature`."
  - variation: "Change the token budget"
    how: "Change `limits` in the AI Rate Limiting Advanced Policy, for example `limits: [{limit: 5000000, window_size: 2592000}]` for 5 million tokens a month. Add several `limits` entries to set a burst limit and a sustained limit in the same policy."
  - variation: "Share rate limit counters"
    how: "Set `strategy: redis` and point the policy at a shared Redis instance, so that all data plane nodes use the same counters."
  - variation: "Add a developer"
    how: "Add an `ai_gateway_consumers` entry with its own credential and re-apply. The AI Model and the policies don't change."
  - variation: "Use single sign-on"
    how: "Replace the Key Auth AI Auth Strategy with an [OpenID Connect](/ai-gateway/openid-connect/) AI Auth Strategy, as in the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/)."
  - variation: "Redact sensitive data"
    how: "Attach an [AI PII Sanitizer](/ai-gateway/policies/ai-sanitizer/) Policy to the AI Model, so that personal data in prompts doesn't reach the provider."
  - variation: "Support other OpenAI-format clients"
    how: "Point any client that speaks the OpenAI Chat Completions API at `/github-copilot` with its own AI Consumer key. See the [Basic LLM Routing cookbook](/cookbooks/basic-llm-routing/)."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration.

The Copilot Usage dashboard is an organization-level resource that outlives the {{site.ai_gateway}}. Delete it first:

```bash
DASHBOARD_IDS=$(kongctl api get "/v2/dashboards?filter%5Blabels.recipe%5D=github-copilot-byok-recipe" \
  --pat "${KONNECT_TOKEN}" -o json --jq '.data[].id' -r)

if [ -z "${DASHBOARD_IDS}" ]; then
  echo "No Copilot Usage dashboard found. Skipping."
else
  for id in ${DASHBOARD_IDS}; do
    if kongctl api delete "/v2/dashboards/${id}" --pat "${KONNECT_TOKEN}"; then
      echo "Deleted Copilot Usage dashboard ${id}."
    else
      echo "Failed to delete dashboard ${id}."
    fi
  done
fi
```
{: data-test-step="block" .collapsible }

Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='github-copilot-byok-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the dashboard definition:

```bash
rm -f copilot-usage-dashboard.json
```

In VS Code, delete the `Kong` entry from `chatLanguageModels.json`, so that Copilot stops showing a model whose endpoint no longer exists.
