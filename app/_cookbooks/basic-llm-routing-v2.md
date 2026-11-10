---
title: Basic LLM Routing
description: Route requests to any supported LLM provider through {{site.ai_gateway_name}} with AI Consumer authentication and per-request model selection.
url: "/cookbooks/basic-llm-routing-v2/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
canonical: true
works_on:
  - konnect
min_version:
  gateway: '3.14'
  ai-gateway: '2.0'
categories:
  - llm
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - ai-model
  - ai-model-provider
requires_embeddings: false
providers:
  - openai
  - anthropic
  - bedrock
  - azure
  - gemini
  - mistral

hint: "Requires API credentials for your chosen LLM provider and Python 3.11+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. You'll provision a recipe-scoped {{site.ai_gateway}} and local data plane via the [quickstart script](https://get.konghq.com/ai).

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
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key as an environment variable:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
        {% endnavtab %}
        {% navtab "Anthropic" %}
        This tutorial uses Anthropic:

        1. [Create an Anthropic account](https://console.anthropic.com/).
        1. [Get an API key](https://console.anthropic.com/settings/keys).
        1. Export the API key and the [Messages API schema version](https://docs.claude.com/en/api/versioning) Kong should send upstream on every request:

           ```sh
           export ANTHROPIC_TOKEN='YOUR-ANTHROPIC-KEY'
           export ANTHROPIC_VERSION='2023-06-01'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        This tutorial uses AWS Bedrock:

        1. Ensure you have an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled.
        1. Export your AWS credentials:

           ```sh
           export AWS_ACCESS_KEY_ID='your-access-key'
           export AWS_SECRET_ACCESS_KEY='your-secret-key'
           export AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure OpenAI" %}
        This tutorial uses Azure OpenAI. Azure binds each deployment to a single model at deployment time, and the deployment ID determines the upstream model ([Azure OpenAI REST API reference](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)). To demonstrate alias routing across two model tiers, you need **two** Azure deployments: one for the `fast` alias and one for `smart`.

        1. [Create an Azure OpenAI resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI).
        1. Deploy two models in your resource (for example, `gpt-4o-mini` for the fast tier and `gpt-4o` for the smart tier). Note both deployment IDs, plus your instance name and API version.
        1. Export your credentials. `AZURE_DEPLOYMENT_ID_1` backs the `fast` alias and `AZURE_DEPLOYMENT_ID_2` backs `smart`. For `AZURE_API_VERSION`, use a current version from the Azure OpenAI REST API reference:

           ```sh
           export AZURE_API_KEY='your-azure-api-key'
           export AZURE_INSTANCE='your-instance-name'
           export AZURE_DEPLOYMENT_ID_1='your-fast-deployment-id'
           export AZURE_DEPLOYMENT_ID_2='your-smart-deployment-id'
           export AZURE_API_VERSION='YOUR-API-VERSION'
           ```

           If you only have one deployment available, point both variables at the same value. The recipe still applies, but both aliases route to the same upstream model.
        {% endnavtab %}
        {% navtab "Google Gemini" %}
        This tutorial uses Google Gemini via Vertex AI:

        1. [Create a Google Cloud project](https://console.cloud.google.com/) with Vertex AI enabled.
        1. Create a service account and mount the JSON key file in your Kong container.
        1. Export your project details:

           ```sh
           export GCP_API_ENDPOINT='your-api-endpoint'
           export GCP_PROJECT_ID='your-project-id'
           export GCP_LOCATION_ID='us-central1'
           ```
        {% endnavtab %}
        {% navtab "Mistral" %}
        This tutorial uses Mistral:

        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Export the API key as an environment variable:

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
  Put {{site.ai_gateway_name}} between your applications and any supported LLM provider. You'll build a
  `/basic-llm-routing` endpoint that:

  * Accepts OpenAI-format chat requests, whichever provider you route to
  * Authenticates each application with its own API key, stored as an AI Consumer credential
  * Routes each request to a cheaper or a stronger upstream model based on the `model` field (`fast` or `smart`)
  * Keeps provider credentials in Kong, so client applications never hold them
---

## What this cookbook solves

When each application calls LLM providers directly, your code depends on provider credentials, request formats, and model IDs, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Every service holds its own copy of the provider API key. A leaked key affects every team, and rotating it needs coordinated redeploys."
    solution: "An AI Model Provider holds the provider credentials in Kong. Each application gets its own AI Consumer API key that you can revoke independently."
  - problem: "Nothing between clients and the provider identifies the caller, so you can't attribute usage, set per-application quotas, or block a single application."
    solution: "A Key Auth AI Auth Strategy validates the `apikey` header on each request and attaches the matching AI Consumer. Kong rejects unknown keys with `401` before any upstream call."
  - problem: "Each provider has its own auth scheme and request format, so switching providers means rewriting client code."
    solution: "The AI Models accept OpenAI-format requests and translate them to the provider's native format. The AI Model Provider injects the provider's auth."
  - problem: "Provider model IDs are hardcoded across applications, so swapping a model needs coordinated redeploys."
    solution: "Two AI Models expose the `fast` and `smart` aliases. Clients send an alias in the `model` field, and you change the upstream model in Kong."
{% endtable %}


## Try it out

Apply the configuration for your provider, then run a demo script that sends one request to each alias and one request with an invalid API key.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your provider's credentials, a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, and two AI Models (`fast` and `smart`) that use that AI Model Provider. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

Adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so that kongctl can manage it. Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the demo AI Consumer's API key. The credential's `api_key` field only accepts a `!secret` reference, so the value must come from an environment variable:

```bash
export CONSUMER_API_KEY='demo-api-key'
```

Select your provider. Each tab exports the two upstream models, where `CHAT_MODEL_1` backs the `fast` alias and `CHAT_MODEL_2` backs `smart`, then applies the configuration. Provider credentials come from the environment variables you set in the prerequisites.

{% navtabs "Providers" %}
{% tab OpenAI %}

Export the model env vars:

```bash
export CHAT_MODEL_1='gpt-4o-mini'
export CHAT_MODEL_2='gpt-4o'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Anthropic %}

Export the model env vars:

```bash
export CHAT_MODEL_1='claude-haiku-4-5-20251001'
export CHAT_MODEL_2='claude-sonnet-4-5-20250929'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab AWS Bedrock %}

Export the model env vars:

```bash
export CHAT_MODEL_1='amazon.nova-lite-v1:0'
export CHAT_MODEL_2='global.anthropic.claude-sonnet-4-5-20250929-v1:0'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Azure OpenAI %}

Export the model env vars. Azure selects the upstream model from the deployment IDs you exported in the prerequisites, and Kong reports these model names in the `X-Kong-LLM-Model` header. Set each name to the model in the matching deployment:

```bash
export CHAT_MODEL_1='gpt-4o-mini'
export CHAT_MODEL_2='gpt-4o'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Google Gemini %}

Export the model env vars:

```bash
export CHAT_MODEL_1='gemini-2.0-flash'
export CHAT_MODEL_2='gemini-1.5-pro'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Mistral %}

Export the model env vars:

```bash
export CHAT_MODEL_1='mistral-small-latest'
export CHAT_MODEL_2='mistral-large-latest'
```

Apply the Kong configuration:

```bash
{%- raw %}
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
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

### Run the demo

The demo script sends the same prompt twice, first with `model: fast` and then with `model: smart`, and prints the `X-Kong-LLM-Model` response header for each. It then sends a request with an invalid API key.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, attach a [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token to the `apikey` header.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Basic LLM routing demo. See README for context."""

import os
import sys
import time

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = "demo-api-key"
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
    # Routed-to model is the headline of this demo — make it pop.
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
    bad_client = make_client("not-a-real-key")
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

Example output (using the OpenAI tab's model env vars):

```text
======================================================================
1. Same client, same prompt, two model aliases
======================================================================

[REQUEST] model='fast' prompt='What is the capital of France?'
[RESPONSE] The capital of France is Paris.
[ROUTED TO] alias='fast' -> upstream model='openai/gpt-4o-mini'
[LATENCY] upstream=1311ms  proxy=12ms  total=1488ms

[REQUEST] model='smart' prompt='What is the capital of France?'
[RESPONSE] The capital of France is Paris.
[ROUTED TO] alias='smart' -> upstream model='openai/gpt-4o'
[LATENCY] upstream=1071ms  proxy=4ms  total=1083ms

======================================================================
2. Invalid API key. Kong rejects before reaching the upstream provider
======================================================================

[REQUEST] model='fast' prompt='What is the capital of France?'
[BLOCKED] 401 Error code: 401 - {'message': 'Unauthorized'}  (30ms)

======================================================================
Done.
======================================================================
```
{:.no-copy-code}

### Check the results

The output confirms the following:

* **Alias routing:** Both requests used the same path and body except for `model`. `X-Kong-LLM-Model` shows a different upstream model for each alias.
* **Auth before the upstream call:** Kong rejected the invalid key with `401` in about 30 ms, without contacting the provider or using provider quota.
* **No provider key on the client:** The client only held the AI Consumer's API key. Kong injected the provider credential into the upstream request.

To review the created entities and per-consumer usage, open the `basic-llm-routing-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.


## How it works

Kong authenticates the request, selects an AI Model from the `model` field in the body, then forwards the request to the provider with the provider's credentials:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant L as LLM Provider

    C->>K: POST /basic-llm-routing (apikey, model: fast or smart)
    activate K
    K->>K: key-auth Auth Strategy: validate apikey, attach Consumer
    K->>K: AI Model: match model to a route.model.values alias
    K->>K: AI Model Provider: inject provider auth
    K->>L: Forwarded request (translated to provider native format)
    activate L
    L-->>K: Native response
    deactivate L
    K-->>C: OpenAI-format response (+ X-Kong-LLM-Model)
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Key Auth AI Auth Strategy and AI Consumer

In {{site.ai_gateway_name}} 2.0, authentication is an AI Auth Strategy, not an AI Policy. Both AI Models list `basic-llm-routing-auth` in `access.auth_strategies`, so one AI Consumer credential works for both aliases. The AI Consumer is the identity that rate limits, ACLs, and analytics use. To support more applications or teams, add one AI Consumer for each.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.key_names: [apikey]`"
    purpose: "The headers or query parameters that Kong checks for the API key. Kong compares the whole value exactly and doesn't parse `Authorization: Bearer` tokens, which is why the demo sends an `apikey` header."
  - setting: "`config.hide_credentials: true`"
    purpose: "Removes the API key from the request before Kong forwards it, so the provider never sees it."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's API key. This field is write-only and must be a `!secret` reference. Kong rejects a plain string."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Model Provider and AI Models

The AI Model Provider holds the credentials for one upstream account. Each AI Model answers to one alias and sends requests to a target that references the AI Model Provider. An AI Model accepts exactly one alias in `config.route.model.values`, so the cookbook defines two AI Models on the same path.

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The provider credentials that Kong injects into every upstream request. The fields depend on the provider, for example an `Authorization` header for OpenAI or AWS keys for Bedrock."
  - setting: "`formats: [{type: openai}]`"
    purpose: "The request format the AI Model accepts. Kong translates requests to the provider's native format and converts responses back to OpenAI format."
  - setting: "`config.route.paths` and `config.route.model`"
    purpose: "Kong matches requests on `/basic-llm-routing`, reads the `model` field from the body, and selects the AI Model whose `values` list contains it."
  - setting: "`targets[].name`"
    purpose: "The upstream model ID. Change it and re-apply to swap models without changing client code."
  - setting: "`targets[].config`"
    purpose: "Provider-specific target settings, such as `region` for Bedrock or `deployment_id` and `api_version` for Azure."
  - setting: "`config.max_request_body_size` and `config.response_streaming`"
    purpose: "The cookbook allows requests up to 10 MB and allows streaming responses, which suits interactive chat. Adjust both for your workload."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the provider credentials in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference both from a secret manager such as AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

### Response headers

Kong adds the following headers to every proxied response:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "The upstream model that served the request, prefixed with the provider name, from the matched AI Model target"
  - header: "`X-Kong-Upstream-Latency`"
    description: The time in milliseconds that Kong waited for the provider to respond
  - header: "`X-Kong-Proxy-Latency`"
    description: The time in milliseconds that Kong spent processing the request, excluding the upstream
{% endtable %}


## Variations and next steps

* **Swap models:** Change `CHAT_MODEL_1` or `CHAT_MODEL_2` and re-apply. Clients keep sending `fast` and `smart`. Keep each alias within the same model class, because moving `fast` to a large model changes behavior that clients rely on.
* **Switch providers:** Select a different provider tab in [Apply the Kong configuration](#apply-the-kong-configuration) and re-apply. The `apikey` header and the `fast` and `smart` aliases don't change.
* **Add per-consumer rate limits:** Attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to give each AI Consumer or AI Consumer Group its own token quota. See the [LLM cost optimization cookbook](/cookbooks/llm-cost-optimization/) for an example.
* **Use OpenID Connect instead of API keys:** Replace the [Key Auth AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) with an [OpenID Connect AI Auth Strategy](/ai-gateway/openid-connect/) and map JWT claims to AI Consumers. The AI Models and AI Model Provider don't change. See the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/) for an example with Okta.
* **Allow anonymous access:** Set `anonymous` on the Key Auth AI Auth Strategy to an AI Consumer ID. Kong then sends unauthenticated requests through that AI Consumer, with its own restricted policies, instead of returning `401`. Run `kongctl explain ai_gateway_auth_strategies --extended` for all options.
* **Pass requests through in the provider's native format:** Set `formats` to the provider's format, for example `anthropic`, to skip translation. A native-format AI Model can only route to providers that use that format.
* **Route by header or path, or load-balance:** AI Models can also select targets by request header or path, or balance across several targets with `config.balancer`. See the [AI Model reference](/ai-gateway/entities/ai-model/).


## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='basic-llm-routing-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
