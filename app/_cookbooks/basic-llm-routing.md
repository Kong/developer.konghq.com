---
title: Basic LLM Routing
description: Route requests to any supported LLM provider through {{site.ai_gateway_name}} with AI Consumer authentication and per-request model selection.
url: "/cookbooks/basic-llm-routing/"
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
  - llm-routing
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

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `basic-llm-routing-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
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
        {% navtab "Anthropic" %}
        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Export the API key and the [Messages API version](https://docs.claude.com/en/api/versioning) that Kong sends upstream on each request:

           ```sh
           export ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           export ANTHROPIC_VERSION='2023-06-01'
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
        {% navtab "Azure OpenAI" %}
        Azure binds each deployment to one model, and the deployment ID selects the upstream model ([Azure OpenAI REST API reference](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)). To route two aliases to two models, you need two deployments.

        1. [Create an Azure OpenAI resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI).
        1. Deploy two models in the resource, for example `gpt-4o-mini` for the `fast` alias and `gpt-4o` for the `smart` alias.
        1. Export your credentials. `AZURE_DEPLOYMENT_ID_1` is the deployment for `fast`, and `AZURE_DEPLOYMENT_ID_2` is the deployment for `smart`. Use the current API version from the Azure OpenAI REST API reference:

           ```sh
           export AZURE_API_KEY='your-azure-api-key'
           export AZURE_INSTANCE='your-instance-name'
           export AZURE_DEPLOYMENT_ID_1='your-fast-deployment-id'
           export AZURE_DEPLOYMENT_ID_2='your-smart-deployment-id'
           export AZURE_API_VERSION='YOUR-API-VERSION'
           ```

           If you have only one deployment, set both deployment IDs to the same value. Both aliases then route to the same upstream model.
        {% endnavtab %}
        {% navtab "Google Gemini" %}
        1. [Create a Google Cloud project](https://console.cloud.google.com/) with Vertex AI enabled.
        1. [Create a service account key](https://cloud.google.com/iam/docs/keys-create-delete) for a service account that can call Vertex AI.
        1. Export the key and your project details:

           ```sh
           export GEMINI_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account-key.json)"
           export GCP_API_ENDPOINT='your-api-endpoint'
           export GCP_PROJECT_ID='your-project-id'
           export GCP_LOCATION_ID='us-central1'
           ```
        {% endnavtab %}
        {% navtab "Mistral" %}
        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Export the API key:

           ```sh
           export MISTRAL_TOKEN='Bearer your-mistral-key'
           ```
        {% endnavtab %}
        {% endnavtabs %}
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Set up an isolated environment:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'openai>=1.0.0'
        ```
overview: |
  Route OpenAI-format chat requests to any supported LLM provider through {{site.ai_gateway_name}}, with AI Consumer authentication and per-request model selection. You'll set up:

  * A `/basic-llm-routing` endpoint that accepts only requests with a valid AI Consumer API key
  * Two model aliases, `fast` and `smart`, that clients select with the `model` field
  * Provider credentials that stay in {{site.ai_gateway}} instead of in client code
---

## What this cookbook solves

Most teams call LLM providers directly from application code, with a copy of the provider API key in each service, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Each service holds a copy of the provider API key. A leaked key affects every team that uses the provider, and rotating it needs coordinated redeploys."
    solution: "The AI Model Provider keeps the provider credentials in Kong and adds them to each upstream request. Clients only hold an AI Consumer key."
  - problem: "Without an authentication layer in front of the provider, nothing attributes usage to an app or revokes access for one misbehaving app."
    solution: "The Key Auth AI Auth Strategy maps each API key to an AI Consumer and rejects unknown keys with `401` before any upstream call."
  - problem: "Each provider has its own authentication (`Authorization: Bearer`, `x-api-key`, SigV4 signing, `api-key`) and its own request and response format, so switching providers means rewriting client code."
    solution: "The AI Model accepts OpenAI-format requests. Kong translates each request to the provider's native format and the response back."
  - problem: "Model IDs are hardcoded in application code, so swapping or upgrading a model needs coordinated redeploys."
    solution: "Two AI Models answer to the aliases `fast` and `smart` on one path. You change the upstream model in Kong, and clients keep sending the same alias."
{% endtable %}

## Try it out

Apply the configuration, then run a demo script that sends a request to each model alias and one request with an invalid API key.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your provider's credentials, a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, and two AI Models (`fast` and `smart`) that route to the AI Model Provider. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the demo AI Consumer's API key. The credential's `api_key` field is write-only, so its value must come from an environment variable, even for a fixed demo key:

```bash
export CONSUMER_API_KEY='demo-api-key'
```

Select your provider. Each tab exports `CHAT_MODEL_1`, the upstream model for the `fast` alias, and `CHAT_MODEL_2`, the upstream model for the `smart` alias, then applies the configuration. Provider credentials come from the prerequisites.

{% navtabs "Providers" %}
{% navtab "OpenAI" %}

Export the model env vars:

```bash
export CHAT_MODEL_1='gpt-4o-mini'
export CHAT_MODEL_2='gpt-4o'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      type: openai
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Anthropic" %}

Export the model env vars:

```bash
export CHAT_MODEL_1='claude-haiku-4-5-20251001'
export CHAT_MODEL_2='claude-sonnet-4-5-20250929'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: anthropic
  config:
    auth:
      type: basic
      headers:
      - name: x-api-key
        value: !secret {source: !env 'ANTHROPIC_TOKEN'}
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      version: !env 'ANTHROPIC_VERSION'
      type: anthropic
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      version: !env 'ANTHROPIC_VERSION'
      type: anthropic
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "AWS Bedrock" %}

Export the model env vars:

```bash
export CHAT_MODEL_1='amazon.nova-lite-v1:0'
export CHAT_MODEL_2='global.anthropic.claude-sonnet-4-5-20250929-v1:0'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: !env 'AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'AWS_SECRET_ACCESS_KEY'}
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      region: !env 'AWS_REGION'
      type: bedrock
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      region: !env 'AWS_REGION'
      type: bedrock
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Azure OpenAI" %}

Kong records these model names in the `X-Kong-LLM-Model` header, but the deployment IDs from the AI Credentials prerequisite select the upstream model. Set each name to the model in the matching deployment:

```bash
export CHAT_MODEL_1='gpt-4o-mini'
export CHAT_MODEL_2='gpt-4o'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
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
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      api_version: !env 'AZURE_API_VERSION'
      deployment_id: !env 'AZURE_DEPLOYMENT_ID_1'
      type: azure
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      api_version: !env 'AZURE_API_VERSION'
      deployment_id: !env 'AZURE_DEPLOYMENT_ID_2'
      type: azure
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Google Gemini" %}

Export the model env vars:

```bash
export CHAT_MODEL_1='gemini-2.0-flash'
export CHAT_MODEL_2='gemini-1.5-pro'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: gemini
  config:
    auth:
      type: gcp
      use_gcp_service_account: true
      service_account_json: !secret {source: !env 'GEMINI_SERVICE_ACCOUNT_JSON'}
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      gcp_environment:
        api_endpoint: !env 'GCP_API_ENDPOINT'
        project_id: !env 'GCP_PROJECT_ID'
        location_id: !env 'GCP_LOCATION_ID'
      type: gemini
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      gcp_environment:
        api_endpoint: !env 'GCP_API_ENDPOINT'
        project_id: !env 'GCP_PROJECT_ID'
        location_id: !env 'GCP_LOCATION_ID'
      type: gemini
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "Mistral" %}

Export the model env vars:

```bash
export CHAT_MODEL_1='mistral-small-latest'
export CHAT_MODEL_2='mistral-large-latest'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: basic-llm-routing-recipe
ai_gateway_model_providers:
- ref: basic-llm-routing-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-provider
  display_name: basic-llm-routing
  type: mistral
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'MISTRAL_TOKEN'}
ai_gateway_auth_strategies:
- ref: basic-llm-routing-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-auth
  display_name: basic-llm-routing key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: basic-llm-routing-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-consumer
  display_name: basic-llm-routing demo consumer
  type: api-key
  credentials:
  - ref: basic-llm-routing-credential
    name: basic-llm-routing-credential
    display_name: basic-llm-routing demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_models:
- ref: basic-llm-routing-fast
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-fast
  display_name: basic-llm-routing (fast)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - fast
  targets:
  - name: !env 'CHAT_MODEL_1'
    provider: basic-llm-routing-provider
    config:
      format: openai
      type: mistral
- ref: basic-llm-routing-smart
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: basic-llm-routing-smart
  display_name: basic-llm-routing (smart)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - basic-llm-routing-auth
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /basic-llm-routing
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
        - smart
  targets:
  - name: !env 'CHAT_MODEL_2'
    provider: basic-llm-routing-provider
    config:
      format: openai
      type: mistral
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

### Run the demo

The script sends the same prompt with `model: fast` and with `model: smart`, then sends one request with an invalid API key. In the output, look for the upstream model on each `[ROUTED TO]` line and the `401` for the invalid key.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Basic LLM routing demo for Kong AI Gateway.

Shows three things:
  1. Two requests with the same prompt and different model aliases (fast, smart)
     reach different upstream models. The X-Kong-LLM-Model response header names
     the upstream model.
  2. Kong authenticates each request with the apikey header.
  3. A request with an invalid key gets 401 from Kong before any upstream call.

Expected output: one [ROUTED TO] line for each alias, with a different upstream
model on each, then a [BLOCKED] 401 line for the invalid key.

Run: python demo.py (set PROXY_URL if the data plane is not at http://localhost:8000).
"""

import os
import sys
import time

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = os.getenv("CONSUMER_API_KEY", "demo-api-key")
PROMPT = "What is the capital of France?"

# ANSI color codes. Disabled when stdout isn't a TTY or NO_COLOR is set.
_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
BOLD  = lambda s: _c("1", s)
DIM   = lambda s: _c("2", s)
GREEN = lambda s: _c("32", s)
CYAN  = lambda s: _c("36", s)
RED   = lambda s: _c("31", s)


def make_client(api_key: str) -> OpenAI:
    """Construct an OpenAI client that sends the given API key in the apikey header."""
    return OpenAI(
        base_url=f"{PROXY_URL}/basic-llm-routing",
        api_key="unused",  # required by the SDK; Kong reads the apikey header instead
        default_headers={"apikey": api_key},
    )


def call(client: OpenAI, model_alias: str) -> None:
    """Send one chat request and print the model Kong routed it to."""
    print(f"\n{BOLD('[REQUEST]')} model={model_alias!r} prompt={PROMPT!r}")
    start_ms = round(time.time() * 1000)
    try:
        raw = client.chat.completions.with_raw_response.create(
            model=model_alias,
            messages=[{"role": "user", "content": PROMPT}],
        )
    except APIStatusError as e:
        elapsed_ms = round(time.time() * 1000) - start_ms
        print(f"{RED(BOLD('[BLOCKED]'))} {RED(BOLD(str(e.status_code)))} {e.message}  ({elapsed_ms}ms)")
        return

    elapsed_ms = round(time.time() * 1000) - start_ms
    completion = raw.parse()
    upstream_latency = raw.headers.get("x-kong-upstream-latency", ".")
    proxy_latency = raw.headers.get("x-kong-proxy-latency", ".")
    upstream_model = raw.headers.get("x-kong-llm-model", ".")
    answer = completion.choices[0].message.content

    print(f"[RESPONSE] {DIM(answer)}")
    print(f"{GREEN(BOLD('[ROUTED TO]'))} alias={model_alias!r} -> upstream model={CYAN(BOLD(upstream_model))}")
    print(f"[LATENCY] {DIM(f'upstream={upstream_latency}ms  proxy={proxy_latency}ms  total={elapsed_ms}ms')}")


def section(title: str) -> None:
    bar = "=" * 70
    print(f"\n{bar}\n{BOLD(title)}\n{bar}")


def main() -> None:
    section("1. Same client, same prompt, two model aliases")
    client = make_client(API_KEY)
    call(client, "fast")
    call(client, "smart")

    section("2. Invalid API key. Kong rejects before reaching the upstream provider")
    bad_key = "not-a-real-key"
    print(f"\nTrying apikey={bad_key!r}")
    bad_client = make_client(bad_key)
    call(bad_client, "fast")

    section("Done.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

Example output with the OpenAI tab's models:

```text
======================================================================
1. Same client, same prompt, two model aliases
======================================================================

[REQUEST] model='fast' prompt='What is the capital of France?'
[RESPONSE] The capital of France is Paris.
[ROUTED TO] alias='fast' -> upstream model=openai/gpt-4o-mini
[LATENCY] upstream=1311ms  proxy=12ms  total=1488ms

[REQUEST] model='smart' prompt='What is the capital of France?'
[RESPONSE] The capital of France is Paris.
[ROUTED TO] alias='smart' -> upstream model=openai/gpt-4o
[LATENCY] upstream=1071ms  proxy=4ms  total=1083ms

======================================================================
2. Invalid API key. Kong rejects before reaching the upstream provider
======================================================================

Trying apikey='not-a-real-key'

[REQUEST] model='fast' prompt='What is the capital of France?'
[BLOCKED] 401 Error code: 401 - Unauthorized  (30ms)

======================================================================
Done.
======================================================================
```
{:.no-copy-code}

### Check the results

The output confirms the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Alias routing"
    evidence: "The `[ROUTED TO]` lines show `openai/gpt-4o-mini` for `fast` and `openai/gpt-4o` for `smart`, from the `X-Kong-LLM-Model` header. Both requests used the same path and the same body, except for the `model` field."
  - behavior: "AI Consumer authentication"
    evidence: "The requests with `demo-api-key` succeed. Kong matched the key to the `basic-llm-routing-consumer` AI Consumer."
  - behavior: "Authentication before any upstream call"
    evidence: "The invalid key gets `401` in about 30 ms, well below the upstream latency. Kong never contacted the provider."
  - behavior: "Provider credentials stay in Kong"
    evidence: "The client only held the AI Consumer key. The AI Model Provider added the provider credentials to each upstream request."
{% endtable %}

To review the created entities, and per-consumer usage, open the `basic-llm-routing-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Kong authenticates each request with the Key Auth AI Auth Strategy, selects the AI Model whose alias matches the `model` field, and sends the request upstream with the AI Model Provider's credentials.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant L as LLM Provider

    C->>K: POST /basic-llm-routing (apikey header, model fast or smart)
    activate K
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>K: Select the AI Model that matches the model alias
    K->>K: AI Model Provider adds provider credentials
    K->>L: Request in the provider's native format
    activate L
    L-->>K: Native response
    deactivate L
    K-->>C: OpenAI-format response with X-Kong-LLM-Model
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use. Both AI Models reference this AI Auth Strategy in `access.auth_strategies`, so one key works for both aliases.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey]`"
    purpose: "Kong reads the key from the `apikey` header. Key Auth compares the whole header value, so it can't read a key from an `Authorization: Bearer` header. The note in [Run the demo](#run-the-demo) shows the workaround."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the key before it forwards the request. The provider never sees the AI Consumer key."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`, even for a demo value."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Models

The AI Model Provider holds the credentials for one provider account. The two AI Models, `basic-llm-routing-fast` and `basic-llm-routing-smart`, share the `/basic-llm-routing` path. Each AI Model answers to one alias in the `model` field and has one target that uses the AI Model Provider. An AI Model accepts only one alias, so each alias needs its own AI Model.

The following settings configure the AI Model Provider and the AI Models:

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
    purpose: "The AI Model accepts OpenAI-format requests. Kong translates each request to the provider's native format and the response back to OpenAI format."
  - setting: "`capabilities: [generate]`"
    purpose: "The AI Model serves chat completions."
  - setting: "`config.route.model`"
    purpose: "Kong reads the `model` field of the request body (`body_param: model`) and selects the AI Model whose `values` entry matches: `fast` or `smart`."
  - setting: "`targets[].name`"
    purpose: "The upstream model, from `CHAT_MODEL_1` or `CHAT_MODEL_2`. Change it and re-apply to swap models without changing clients."
  - setting: "`targets[].config`"
    purpose: "The provider `type` and provider-specific target fields, for example Bedrock's `region` or Azure's `deployment_id` and `api_version`."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so you can call the local data plane at `http://localhost:8000`."
  - setting: "`config.route.strip_path: true`"
    purpose: "Kong removes `/basic-llm-routing` from the path before it forwards the request."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default, for long conversation contexts."
  - setting: "`config.response_streaming: allow`"
    purpose: "Clients can request streamed responses, for interactive chat."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. The default is `false`."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the provider credentials in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

### Response headers

Kong adds the following response headers:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "The upstream model that served the request, with the provider name as a prefix, for example `openai/gpt-4o-mini`."
  - header: "`X-Kong-Upstream-Latency`"
    description: "Time in milliseconds that Kong waited for the provider to respond."
  - header: "`X-Kong-Proxy-Latency`"
    description: "Time in milliseconds that Kong spent processing the request, excluding the upstream call."
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
  - variation: "Swap models"
    how: "Change `CHAT_MODEL_1` or `CHAT_MODEL_2` and re-apply. Clients keep sending `fast` and `smart`. Keep each alias in the same model class, because a large change in model behavior affects every client of that alias."
  - variation: "Switch providers"
    how: "Select a different provider tab in [Apply the Kong configuration](#apply-the-kong-configuration) and re-apply. Clients keep the same endpoint, `apikey` header, and aliases."
  - variation: "Allow anonymous requests"
    how: "Set `anonymous` on the Key Auth AI Auth Strategy to an AI Consumer ID. Kong then sends requests without a valid key through that AI Consumer, with its own restricted policies, instead of rejecting them with `401`. This suits public or free-tier endpoints. Run `kongctl explain ai_gateway_auth_strategies --extended` for all options."
  - variation: "Use a native provider format"
    how: "Set `formats` to a provider's native format (for example, `anthropic`) to pass requests through without translation. A native format works only with providers that accept it. See the [AI Model reference](/ai-gateway/entities/ai-model/) for the supported formats."
  - variation: "Route by header, path, or load balancing"
    how: "Route with `config.route.headers`, with one AI Model for each path, or across several targets on one AI Model with `config.balancer`. See the [AI Model reference](/ai-gateway/entities/ai-model/) for the balancer algorithms."
  - variation: "Add per-consumer token limits"
    how: "Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to give each AI Consumer or AI Consumer Group its own token budget. See the [LLM cost optimization cookbook](/cookbooks/llm-cost-optimization/) for an example."
  - variation: "Authenticate users with an identity provider"
    how: "Replace the Key Auth AI Auth Strategy with an [OpenID Connect AI Auth Strategy](/ai-gateway/openid-connect/) and map JWT claims to AI Consumers. The AI Models and AI Model Provider don't change. See the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/) for an example with Okta."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
