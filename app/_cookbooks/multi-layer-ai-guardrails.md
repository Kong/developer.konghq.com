---
title: Multi-Layer AI Guardrails
description: Defense-in-depth content safety using regex filtering, semantic analysis, and PII protection in a single gateway route.
url: "/cookbooks/multi-layer-ai-guardrails/"
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
  - guardrails
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
           export KONNECT_CONTROL_PLANE_NAME='multi-layer-ai-guardrails-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `multi-layer-ai-guardrails-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        Pick the provider you want to route to and export its credentials. The same provider serves chat and embeddings. The provider's tab in [Apply the Kong configuration](#apply-the-kong-configuration) reads these variables.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
        {% endnavtab %}
        {% navtab "AWS Bedrock" %}
        1. Get an AWS account with [Bedrock model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) enabled for a chat model and for Amazon Titan Text Embeddings V2.
        1. Export your AWS credentials and region:

           ```sh
           export AWS_ACCESS_KEY_ID='your-access-key'
           export AWS_SECRET_ACCESS_KEY='your-secret-key'
           export AWS_REGION='us-east-1'
           ```
        {% endnavtab %}
        {% navtab "Azure OpenAI" %}
        Azure binds each deployment to one model, so the recipe needs two deployments: one for chat and one for embeddings.

        1. [Create an Azure OpenAI resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesOpenAI).
        1. Deploy a chat model, for example `gpt-4o`, and the `text-embedding-3-large` embeddings model in the resource.
        1. Export your credentials and both deployment IDs. Use the current API version from the [Azure OpenAI REST API reference](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference):

           ```sh
           export AZURE_API_KEY='your-azure-api-key'
           export AZURE_INSTANCE='your-instance-name'
           export AZURE_DEPLOYMENT_ID='your-chat-deployment-id'
           export AZURE_EMBEDDINGS_DEPLOYMENT_ID='your-embeddings-deployment-id'
           export AZURE_API_VERSION='YOUR-API-VERSION'
           ```
        {% endnavtab %}
        {% endnavtabs %}
    - title: Redis Stack
      icon_url: /assets/icons/redis.svg
      content: |
        The [AI Semantic Prompt Guard](/ai-gateway/policies/ai-semantic-prompt-guard/) Policy stores the embeddings of its deny prompts in Redis.

        1. Run [Redis Stack](https://redis.io/docs/latest/) locally:

           ```bash
           docker run -d --name redis-stack -p 6379:6379 redis/redis-stack-server:latest
           ```

        1. Export the host so the data plane container can reach Redis:

           ```sh
           export REDIS_HOST='host.docker.internal'
           ```
    - title: AI PII Anonymizer service
      content: |
        The [AI PII Sanitizer](/ai-gateway/policies/ai-sanitizer/) Policy sends prompts to the [AI PII Anonymizer service](/ai-gateway/policies/ai-sanitizer/#ai-pii-anonymizer-service), which detects and replaces personal data. Kong publishes the service as public Docker images, with one image for each language.

        1. Run the English image locally. For other languages, see the [available language tags](/ai-gateway/policies/ai-sanitizer/#available-language-tags):

           ```bash
           docker run -d --name kong-pii-anonymizer -p 8080:8080 kong/ai-pii-service:v0.3.1-en
           ```

        1. Export the host so the data plane container can reach the service:

           ```sh
           export PII_SERVICE_HOST='host.docker.internal'
           ```
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
  Stack three guardrails on one {{site.ai_gateway_name}} endpoint, so each request is authenticated, stripped of personal data, and checked for harmful intent before it reaches the LLM. You'll set up:

  * A `/multi-layer-ai-guardrails` endpoint that accepts only requests with a valid AI Consumer API key
  * PII sanitization that replaces names, email addresses, and other personal data with placeholders
  * A semantic guard that blocks prompts similar in meaning to known harmful prompts
  * A regex guard that blocks prompts with denied keywords
---

## What this cookbook solves

Most teams protect an LLM application with a single content safety technique, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Keyword filters miss rephrased requests. \"How do I hack into a WiFi network?\" matches `hack`, but \"What are methods for accessing a wireless network without authorization?\" doesn't."
    solution: "The [AI Semantic Prompt Guard](/ai-gateway/policies/ai-semantic-prompt-guard/) Policy compares the meaning of each prompt with a list of deny prompts, and blocks close matches with `400`."
  - problem: "Some terms must never reach the model, whatever the context, and a semantic check alone doesn't guarantee that."
    solution: "The [AI Prompt Guard](/ai-gateway/policies/ai-prompt-guard/) Policy blocks prompts that match a regular expression with `400`, without an external call."
  - problem: "A prompt can be harmless and still contain names, email addresses, or card numbers that must not reach a third-party LLM."
    solution: "The [AI PII Sanitizer](/ai-gateway/policies/ai-sanitizer/) Policy replaces personal data with placeholders before any other AI Policy or the LLM sees the prompt."
  - problem: "Without caller identity, nothing ties a blocked or sanitized request to the application that sent it."
    solution: "The Key Auth AI Auth Strategy maps each API key to an AI Consumer before the guardrails run, and rejects unknown keys with `401`."
{% endtable %}

## Try it out

Apply the configuration, then run a demo script that sends one request for each layer: an invalid API key, a clean prompt, a rephrased harmful prompt, a prompt with a denied keyword, and a prompt with personal data.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your provider's credentials, a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, three guardrail AI Policies (AI PII Sanitizer, AI Semantic Prompt Guard, and AI Prompt Guard), and an AI Model that references them. A kongctl namespace scopes every resource, so you can remove this configuration without affecting anything else on the same {{site.ai_gateway}}. See the [kongctl documentation](/kongctl/) for more on namespaces.

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

Select your provider. Each tab exports `CHAT_MODEL`, the upstream chat model, and `EMBEDDINGS_MODEL`, the model that the AI Semantic Prompt Guard Policy uses for embeddings, then applies the configuration. Each tab's configuration sets the embedding dimensions of that tab's embeddings model. Provider credentials, the Redis host, and the PII service host come from the prerequisites.

{% navtabs "Providers" %}
{% navtab "OpenAI" %}

Export the model env vars:

```bash
export CHAT_MODEL='gpt-4o'
export EMBEDDINGS_MODEL='text-embedding-3-large'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: multi-layer-ai-guardrails-recipe
ai_gateway_model_providers:
- ref: multi-layer-ai-guardrails-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-provider
  display_name: multi-layer-ai-guardrails
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: multi-layer-ai-guardrails-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-auth
  display_name: multi-layer-ai-guardrails key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: multi-layer-ai-guardrails-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-consumer
  display_name: multi-layer-ai-guardrails demo consumer
  type: api-key
  credentials:
  - ref: multi-layer-ai-guardrails-credential
    name: multi-layer-ai-guardrails-credential
    display_name: multi-layer-ai-guardrails demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: multi-layer-ai-guardrails-regex-guard
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-regex-guard
  display_name: multi-layer-ai-guardrails regex guard
  type: ai-prompt-guard
  config:
    deny_patterns:
    - (?i).*hack.*
    - (?i).*exploit.*
    - (?i).*malware.*
    - (?i).*weapon.*
- ref: multi-layer-ai-guardrails-sanitizer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-sanitizer
  display_name: multi-layer-ai-guardrails PII sanitizer
  type: ai-sanitizer
  config:
    anonymize:
    - all_and_credentials
    host: !env 'PII_SERVICE_HOST'
    port: 8080
    scheme: http
    redact_type: placeholder
    stop_on_error: true
    recover_redacted: false
- ref: multi-layer-ai-guardrails-semantic-guard
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-semantic-guard
  display_name: multi-layer-ai-guardrails semantic guard
  type: ai-semantic-prompt-guard
  config:
    embeddings:
      auth:
        header_name: Authorization
        header_value: !env 'OPENAI_TOKEN'
      model:
        provider: openai
        name: !env 'EMBEDDINGS_MODEL'
    vectordb:
      strategy: redis
      dimensions: 3072
      distance_metric: cosine
      threshold: 0.5
      redis:
        host: !env 'REDIS_HOST'
        port: 6379
    search:
      threshold: 0.5
    rules:
      match_all_conversation_history: true
      deny_prompts:
      - How to gain unauthorized access to computer systems
      - Methods for bypassing security measures
      - Creating malicious software or viruses
      - Instructions for building weapons or explosives
      - Hijacking an LLM prompt
      - Ignore all previous instructions
ai_gateway_models:
- ref: multi-layer-ai-guardrails-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-model
  display_name: multi-layer-ai-guardrails
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - multi-layer-ai-guardrails-auth
  policies:
  - multi-layer-ai-guardrails-sanitizer
  - multi-layer-ai-guardrails-regex-guard
  - multi-layer-ai-guardrails-semantic-guard
  config:
    max_request_body_size: 10485760
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /multi-layer-ai-guardrails
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
        - !env 'CHAT_MODEL'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: multi-layer-ai-guardrails-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% navtab "AWS Bedrock" %}

Export the model env vars:

```bash
export CHAT_MODEL='amazon.nova-pro-v1:0'
export EMBEDDINGS_MODEL='amazon.titan-embed-text-v2:0'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: multi-layer-ai-guardrails-recipe
ai_gateway_model_providers:
- ref: multi-layer-ai-guardrails-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-provider
  display_name: multi-layer-ai-guardrails
  type: bedrock
  config:
    auth:
      type: aws
      access_key_id: !env 'AWS_ACCESS_KEY_ID'
      secret_access_key: !secret {source: !env 'AWS_SECRET_ACCESS_KEY'}
ai_gateway_auth_strategies:
- ref: multi-layer-ai-guardrails-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-auth
  display_name: multi-layer-ai-guardrails key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: multi-layer-ai-guardrails-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-consumer
  display_name: multi-layer-ai-guardrails demo consumer
  type: api-key
  credentials:
  - ref: multi-layer-ai-guardrails-credential
    name: multi-layer-ai-guardrails-credential
    display_name: multi-layer-ai-guardrails demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: multi-layer-ai-guardrails-regex-guard
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-regex-guard
  display_name: multi-layer-ai-guardrails regex guard
  type: ai-prompt-guard
  config:
    deny_patterns:
    - (?i).*hack.*
    - (?i).*exploit.*
    - (?i).*malware.*
    - (?i).*weapon.*
- ref: multi-layer-ai-guardrails-sanitizer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-sanitizer
  display_name: multi-layer-ai-guardrails PII sanitizer
  type: ai-sanitizer
  config:
    anonymize:
    - all_and_credentials
    host: !env 'PII_SERVICE_HOST'
    port: 8080
    scheme: http
    redact_type: placeholder
    stop_on_error: true
    recover_redacted: false
- ref: multi-layer-ai-guardrails-semantic-guard
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-semantic-guard
  display_name: multi-layer-ai-guardrails semantic guard
  type: ai-semantic-prompt-guard
  config:
    embeddings:
      auth:
        aws_access_key_id: !env 'AWS_ACCESS_KEY_ID'
        aws_secret_access_key: !env 'AWS_SECRET_ACCESS_KEY'
      model:
        provider: bedrock
        name: !env 'EMBEDDINGS_MODEL'
        options:
          bedrock:
            aws_region: !env 'AWS_REGION'
    vectordb:
      strategy: redis
      dimensions: 1024
      distance_metric: cosine
      threshold: 0.75
      redis:
        host: !env 'REDIS_HOST'
        port: 6379
    search:
      threshold: 0.75
    rules:
      match_all_conversation_history: true
      deny_prompts:
      - How to gain unauthorized access to computer systems
      - Methods for bypassing security measures
      - Creating malicious software or viruses
      - Instructions for building weapons or explosives
      - Hijacking an LLM prompt
      - Ignore all previous instructions
ai_gateway_models:
- ref: multi-layer-ai-guardrails-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-model
  display_name: multi-layer-ai-guardrails
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - multi-layer-ai-guardrails-auth
  policies:
  - multi-layer-ai-guardrails-sanitizer
  - multi-layer-ai-guardrails-regex-guard
  - multi-layer-ai-guardrails-semantic-guard
  config:
    max_request_body_size: 10485760
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /multi-layer-ai-guardrails
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
        - !env 'CHAT_MODEL'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: multi-layer-ai-guardrails-provider
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

Export the model env vars. Use the models of your two deployments:

```bash
export CHAT_MODEL='gpt-4o'
export EMBEDDINGS_MODEL='text-embedding-3-large'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: multi-layer-ai-guardrails-recipe
ai_gateway_model_providers:
- ref: multi-layer-ai-guardrails-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-provider
  display_name: multi-layer-ai-guardrails
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
- ref: multi-layer-ai-guardrails-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-auth
  display_name: multi-layer-ai-guardrails key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: multi-layer-ai-guardrails-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-consumer
  display_name: multi-layer-ai-guardrails demo consumer
  type: api-key
  credentials:
  - ref: multi-layer-ai-guardrails-credential
    name: multi-layer-ai-guardrails-credential
    display_name: multi-layer-ai-guardrails demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: multi-layer-ai-guardrails-regex-guard
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-regex-guard
  display_name: multi-layer-ai-guardrails regex guard
  type: ai-prompt-guard
  config:
    deny_patterns:
    - (?i).*hack.*
    - (?i).*exploit.*
    - (?i).*malware.*
    - (?i).*weapon.*
- ref: multi-layer-ai-guardrails-sanitizer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-sanitizer
  display_name: multi-layer-ai-guardrails PII sanitizer
  type: ai-sanitizer
  config:
    anonymize:
    - all_and_credentials
    host: !env 'PII_SERVICE_HOST'
    port: 8080
    scheme: http
    redact_type: placeholder
    stop_on_error: true
    recover_redacted: false
- ref: multi-layer-ai-guardrails-semantic-guard
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-semantic-guard
  display_name: multi-layer-ai-guardrails semantic guard
  type: ai-semantic-prompt-guard
  config:
    embeddings:
      auth:
        header_name: api-key
        header_value: !env 'AZURE_API_KEY'
      model:
        provider: azure
        name: !env 'EMBEDDINGS_MODEL'
        options:
          azure:
            instance: !env 'AZURE_INSTANCE'
            api_version: !env 'AZURE_API_VERSION'
            deployment_id: !env 'AZURE_EMBEDDINGS_DEPLOYMENT_ID'
    vectordb:
      strategy: redis
      dimensions: 3072
      distance_metric: cosine
      threshold: 0.5
      redis:
        host: !env 'REDIS_HOST'
        port: 6379
    search:
      threshold: 0.5
    rules:
      match_all_conversation_history: true
      deny_prompts:
      - How to gain unauthorized access to computer systems
      - Methods for bypassing security measures
      - Creating malicious software or viruses
      - Instructions for building weapons or explosives
      - Hijacking an LLM prompt
      - Ignore all previous instructions
ai_gateway_models:
- ref: multi-layer-ai-guardrails-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: multi-layer-ai-guardrails-model
  display_name: multi-layer-ai-guardrails
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - multi-layer-ai-guardrails-auth
  policies:
  - multi-layer-ai-guardrails-sanitizer
  - multi-layer-ai-guardrails-regex-guard
  - multi-layer-ai-guardrails-semantic-guard
  config:
    max_request_body_size: 10485760
    response_streaming: deny
    logging:
      payloads: true
    route:
      paths:
      - /multi-layer-ai-guardrails
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
        - !env 'CHAT_MODEL'
  targets:
  - name: !env 'CHAT_MODEL'
    provider: multi-layer-ai-guardrails-provider
    config:
      api_version: !env 'AZURE_API_VERSION'
      deployment_id: !env 'AZURE_DEPLOYMENT_ID'
      type: azure
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

### Run the demo

The script sends one request with an invalid API key, then four requests with the demo API key: a clean prompt, a rephrased harmful prompt, a benign prompt with a denied keyword, and a prompt with a name and an email address. In the output, look for the `401`, the two `400` blocks, and the placeholders in the last response.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Multi-layer AI guardrails demo.

Sends five OpenAI-format chat requests to the /multi-layer-ai-guardrails AI Model, one for
each layer of the chain:

1. An invalid API key. The Key Auth AI Auth Strategy rejects it with 401 before any
   guardrail runs ([BLOCKED BY KEY AUTH]).
2. A clean prompt. It passes every guardrail and reaches the LLM ([ALLOWED]).
3. A rephrased harmful prompt with no blocked keyword. The AI Semantic Prompt Guard Policy
   blocks it with 400 ([BLOCKED BY SEMANTIC GUARD]).
4. A benign prompt that contains a blocked keyword. The semantic guard lets it through, and
   the AI Prompt Guard Policy blocks it with 400 ([BLOCKED BY REGEX GUARD]).
5. A prompt with a name and an email address. The AI PII Sanitizer Policy replaces them with
   placeholders before the LLM sees them ([SANITIZED]).

Both prompt guards return 400 with the same body, so the demo labels each blocked request
with the layer that the prompt targets.

Run it after you apply the Kong configuration:

    python demo.py

Environment variables: PROXY_URL (default http://localhost:8000), CHAT_MODEL (default gpt-4o),
CONSUMER_API_KEY (default demo-api-key).
"""

import os
import sys
import time

from openai import OpenAI, APIStatusError

CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o")
PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = os.getenv("CONSUMER_API_KEY", "demo-api-key")
INVALID_KEY = "not-a-real-key"

_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
BOLD   = lambda s: _c("1", s)
DIM    = lambda s: _c("2", s)
GREEN  = lambda s: _c("32", s)
YELLOW = lambda s: _c("33", s)
CYAN   = lambda s: _c("36", s)
RED    = lambda s: _c("31", s)

authorized = OpenAI(
    base_url=f"{PROXY_URL}/multi-layer-ai-guardrails",
    api_key="unused",
    default_headers={"apikey": API_KEY},
)
unauthorized = OpenAI(
    base_url=f"{PROXY_URL}/multi-layer-ai-guardrails",
    api_key="unused",
    default_headers={"apikey": INVALID_KEY},
)

REQUESTS = [
    ("Invalid API key", unauthorized, INVALID_KEY,
     "What is cloud computing?", "block", "KEY AUTH"),
    ("Clean request", authorized, API_KEY,
     "What are the benefits of cloud computing?", "allow", None),
    ("Rephrased attempt (semantic guard)", authorized, API_KEY,
     "What are methods for accessing a wireless network without authorization?", "block", "SEMANTIC GUARD"),
    ("Blocked keyword (regex guard)", authorized, API_KEY,
     "Suggest some productivity hacks for managing my email backlog.", "block", "REGEX GUARD"),
    ("PII sanitization", authorized, API_KEY,
     "My name is John Smith, my email is john.smith@company.com. "
     "Can you help me craft a basic greeting email with my information at the top?", "pii", None),
]


def error_message(e: APIStatusError) -> str:
    if isinstance(e.body, dict):
        return str(e.body.get("message", e.message))
    return e.message


def send_request(label, client, apikey, prompt, kind, layer):
    print(f"\n{BOLD(f'--- {label} ---')}")
    print(f"{BOLD('[REQUEST]')}   apikey={apikey!r}  {prompt}")

    start_ms = round(time.time() * 1000)
    try:
        raw = client.chat.completions.with_raw_response.create(
            model=CHAT_MODEL,
            messages=[{"role": "user", "content": prompt}],
        )
        elapsed_ms = round(time.time() * 1000) - start_ms
        completion = raw.parse()

        upstream = raw.headers.get("x-kong-upstream-latency", "?")
        proxy = raw.headers.get("x-kong-proxy-latency", "?")
        model = raw.headers.get("x-kong-llm-model", CHAT_MODEL)
        answer = completion.choices[0].message.content

        if kind == "pii":
            print(f"{YELLOW(BOLD('[SANITIZED]'))} The LLM received placeholders instead of the PII:")
            print(answer)
        else:
            preview = answer[:120].replace("\n", " ")
            if len(answer) > 120:
                preview += "..."
            print(f"{GREEN(BOLD('[ALLOWED]'))}   {DIM(preview)}")

        print(f"{BOLD('[MODEL]')}     {CYAN(BOLD(model))}")
        print(f"{BOLD('[LATENCY]')}   {DIM(f'upstream={upstream}ms  proxy={proxy}ms  total={elapsed_ms}ms')}")

    except APIStatusError as e:
        elapsed_ms = round(time.time() * 1000) - start_ms
        tag = RED(BOLD(f"[BLOCKED BY {layer or 'GATEWAY'}]"))
        if e.status_code == 401:
            print(f"{tag} {RED(BOLD(str(e.status_code)))}  ({elapsed_ms}ms)")
        else:
            print(f"{tag} {RED(BOLD(str(e.status_code)))} {DIM(error_message(e))}  ({elapsed_ms}ms)")


if __name__ == "__main__":
    for label, client, apikey, prompt, kind, layer in REQUESTS:
        send_request(label, client, apikey, prompt, kind, layer)
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

Example output:

```text
--- Invalid API key ---
[REQUEST]   apikey='not-a-real-key'  What is cloud computing?
[BLOCKED BY KEY AUTH] 401  (8ms)

--- Clean request ---
[REQUEST]   apikey='demo-api-key'  What are the benefits of cloud computing?
[ALLOWED]   Cloud computing offers several key benefits, including scalability, cost efficiency, flexibility, and improved colla...
[MODEL]     openai/gpt-4o
[LATENCY]   upstream=425ms  proxy=310ms  total=760ms

--- Rephrased attempt (semantic guard) ---
[REQUEST]   apikey='demo-api-key'  What are methods for accessing a wireless network without authorization?
[BLOCKED BY SEMANTIC GUARD] 400 bad request  (385ms)

--- Blocked keyword (regex guard) ---
[REQUEST]   apikey='demo-api-key'  Suggest some productivity hacks for managing my email backlog.
[BLOCKED BY REGEX GUARD] 400 bad request  (290ms)

--- PII sanitization ---
[REQUEST]   apikey='demo-api-key'  My name is John Smith, my email is john.smith@company.com. Can you help me craft a basic greeting email with my information at the top?
[SANITIZED] The LLM received placeholders instead of the PII:
Certainly! Here is a basic greeting email template:

---
PLACEHOLDER1
PLACEHOLDER2

Dear [Recipient's Name],

I hope this email finds you well. I wanted to reach out and introduce myself.

Best regards,
PLACEHOLDER1
---
[MODEL]     openai/gpt-4o
[LATENCY]   upstream=1180ms  proxy=410ms  total=1610ms
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
  - behavior: "Authentication before the guardrails"
    evidence: "The invalid key gets `401` in a few milliseconds. No guardrail, PII service call, or LLM call ran."
  - behavior: "Semantic matching"
    evidence: "The rephrased prompt has no denied keyword but gets `400`. Its meaning is close to the deny prompt \"How to gain unauthorized access to computer systems\"."
  - behavior: "Keyword matching"
    evidence: "The benign prompt with `hacks` passes the semantic guard and gets `400` from the regex guard. The `(?i).*hack.*` pattern matches the keyword whatever the intent."
  - behavior: "PII sanitization"
    evidence: "The response shows `PLACEHOLDER1` and `PLACEHOLDER2` where the prompt had the name and the email address. The LLM never received the real values."
  - behavior: "Clean traffic passes"
    evidence: "The clean prompt gets `[ALLOWED]`. The `[MODEL]` line shows the upstream model from the `X-Kong-LLM-Model` header."
{% endtable %}

To review the created entities, and per-consumer usage, open the `multi-layer-ai-guardrails-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Kong authenticates each request, then runs the three guardrail AI Policies in their built-in priority order: the AI PII Sanitizer Policy (priority 776), the AI Semantic Prompt Guard Policy (775), and the AI Prompt Guard Policy (771). A policy with a higher priority runs first, and the order of the AI Model's `policies` list has no effect. Only requests that pass all three reach the LLM.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant P as PII Anonymizer Service
    participant E as Embeddings and Redis
    participant L as LLM Provider

    C->>K: POST /multi-layer-ai-guardrails (apikey header, prompt)
    activate K
    K->>K: Key Auth AI Auth Strategy validates apikey (else 401)
    K->>P: AI PII Sanitizer Policy sends the prompt
    activate P
    P-->>K: Prompt with placeholders
    deactivate P
    K->>E: AI Semantic Prompt Guard Policy embeds the prompt and searches the deny prompts
    activate E
    E-->>K: Closest deny prompt and distance
    deactivate E
    K->>K: AI Semantic Prompt Guard Policy blocks close matches (else 400)
    K->>K: AI Prompt Guard Policy checks deny patterns (else 400)
    K->>K: AI Model Provider adds provider credentials
    K->>L: Sanitized request in the provider's native format
    activate L
    L-->>K: Native response
    deactivate L
    K-->>C: OpenAI-format response with X-Kong-LLM-Model
    deactivate K
{% endmermaid %}
<!-- vale on -->

The [AI Policy priority](/ai-gateway/entities/ai-policy/#ai-policy-priority) table lists the priority of each AI Policy type. Because the semantic guard runs before the regex guard, a prompt with a denied keyword still costs one embeddings call.

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use. Kong rejects an unknown key before any guardrail runs, so unauthenticated traffic never uses the PII service, the embeddings model, or the LLM.

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

### AI PII Sanitizer Policy

The AI PII Sanitizer Policy sends the prompt to the AI PII Anonymizer service, which replaces each detected value with a placeholder, `PLACEHOLDER<N>`. Identical values get the same placeholder. The policy runs first, so the two prompt guards and the LLM see only the sanitized prompt.

The following settings configure the AI PII Sanitizer Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`anonymize: [all_and_credentials]`"
    purpose: "Detects every supported type of personal data, and credentials. List single types, for example `email` or `creditcard`, to narrow the scope."
  - setting: "`host`, `port`, and `scheme`"
    purpose: "The address of the AI PII Anonymizer service: `PII_SERVICE_HOST`, port `8080`, over `http`."
  - setting: "`redact_type: placeholder`"
    purpose: "Replaces each value with a placeholder. `synthetic` replaces it with a realistic fake value instead."
  - setting: "`recover_redacted: false`"
    purpose: "Keeps the placeholders in the response. With `true`, Kong puts the original values back before it returns the response to the client."
  - setting: "`stop_on_error: true`"
    purpose: "Stops processing the request when the PII service fails, so an outage doesn't send unsanitized prompts to the LLM."
{% endtable %}

### AI Semantic Prompt Guard Policy

The AI Semantic Prompt Guard Policy embeds the prompt with the provider's embeddings model and searches Redis for the closest deny prompt. A match within the distance threshold blocks the request with `400` and the message `bad request`, the default `rejection_mode: none` response. The policy catches rephrased requests that no keyword list covers.

The following settings configure the AI Semantic Prompt Guard Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`embeddings.auth` and `embeddings.model`"
    purpose: "The embeddings credentials and model, from the AI Credentials prerequisite and `EMBEDDINGS_MODEL`. The policy calls the provider directly and doesn't use the AI Model Provider, so each provider tab has its own auth fields."
  - setting: "`vectordb.dimensions`"
    purpose: "The vector size of the embeddings model: `3072` for `text-embedding-3-large`, `1024` for `amazon.titan-embed-text-v2:0`. If you change `EMBEDDINGS_MODEL`, change this value."
  - setting: "`vectordb.threshold` and `search.threshold`"
    purpose: "The maximum cosine distance for a match. Lower values are stricter. The OpenAI and Azure OpenAI tabs use `0.5`: with `text-embedding-3-large`, `0.75` also blocked the PII example. The AWS Bedrock tab uses `0.75`, which this cookbook hasn't tested with Titan embeddings. Tune the value for each embeddings model. See [Embedding-based similarity matching](/ai-gateway/semantic-similarity/)."
  - setting: "`vectordb.redis.host`"
    purpose: "The Redis Stack instance that stores the deny prompt embeddings, from `REDIS_HOST`."
  - setting: "`rules.deny_prompts`"
    purpose: "Examples of prompts to block. The policy blocks prompts close in meaning, so the list doesn't need every wording."
  - setting: "`rules.match_all_conversation_history: true`"
    purpose: "Checks earlier `user` messages too. The default checks only the latest `user` message."
{% endtable %}

### AI Prompt Guard Policy

The AI Prompt Guard Policy checks `user` messages against regular expressions in the data plane, with no external call. A match blocks the request with `400`, the default `rejection_mode: none` response. It enforces terms that must never reach the model, whatever the wording around them.

The following settings configure the AI Prompt Guard Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`deny_patterns`"
    purpose: "Case-insensitive patterns for `hack`, `exploit`, `malware`, and `weapon`. The patterns also match benign words, for example \"productivity hacks\". Add `allow_patterns` to define what's allowed, and note that a deny match always wins."
{% endtable %}

### AI Model Provider and AI Model

The AI Model Provider holds the provider credentials. The `multi-layer-ai-guardrails-model` AI Model references the AI Auth Strategy and the three guardrail AI Policies, and routes the request to one target.

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
  - setting: "`policies`"
    purpose: "The three guardrail AI Policies. Kong runs them in priority order, not in list order."
  - setting: "`formats: [{type: openai}]`"
    purpose: "The AI Model accepts OpenAI-format requests. Kong translates each request to the provider's native format and the response back to OpenAI format."
  - setting: "`config.route.model`"
    purpose: "The AI Model answers to the `CHAT_MODEL` value in the body's `model` field (`body_param: model`), which the demo sends. Without a selector, an AI Model accepts only its own name as `model`."
  - setting: "`targets[].name` and `targets[].config`"
    purpose: "The upstream model, from `CHAT_MODEL`, and provider-specific fields, for example Bedrock's `region` or Azure's `deployment_id` and `api_version`."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so you can call the local data plane at `http://localhost:8000`."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default, for long conversation contexts."
  - setting: "`config.response_streaming: deny`"
    purpose: "Disables streamed responses, so each response is complete. Keep it if you add response checks, for example `sanitization_mode: BOTH`."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. The default is `false`. Review payload logging against your data retention rules."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the provider credentials in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

### Response headers

Kong adds the following response headers to allowed requests:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "The upstream model that served the request, with the provider name as a prefix, for example `openai/gpt-4o`."
  - header: "`X-Kong-Upstream-Latency`"
    description: "Time in milliseconds that Kong waited for the provider to respond."
  - header: "`X-Kong-Proxy-Latency`"
    description: "Time in milliseconds that Kong spent processing the request, including the PII service call and the embeddings search."
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
  - variation: "Tune the guards"
    how: "Add domain-specific `deny_prompts` and `deny_patterns`, and lower or raise the semantic threshold. Retune the threshold when you change the embeddings model."
  - variation: "Show which guard blocked a request"
    how: "Set `rejection_mode: verbose` on both prompt guards. Kong then returns `403` with the AI Policy name and the reason. Use `verbose` only for trusted clients, because it reveals how the guardrails work."
  - variation: "Restore the original values"
    how: "Set `recover_redacted: true` on the AI PII Sanitizer Policy. The LLM still sees placeholders, and the client gets its own values back."
  - variation: "Check LLM responses"
    how: "Set `sanitization_mode: BOTH` on the AI PII Sanitizer Policy, and add the [AI Semantic Response Guard](/ai-gateway/policies/ai-semantic-response-guard/) Policy to block harmful responses."
  - variation: "Add a system prompt"
    how: "Add the [AI Prompt Decorator](/ai-gateway/policies/ai-prompt-decorator/) Policy to prepend instructions to each request, or the [AI Prompt Template](/ai-gateway/policies/ai-prompt-template/) Policy to accept only approved prompt formats."
  - variation: "Add an external guardrail service"
    how: "Add the [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/) Policy to call a moderation API, for example Azure AI Content Safety. See the [Guardrail integrations cookbook](/cookbooks/guardrail-integrations/) for an example."
  - variation: "Switch providers"
    how: "Select a different provider tab in [Apply the Kong configuration](#apply-the-kong-configuration) and re-apply. The AI PII Sanitizer and AI Prompt Guard Policies don't change."
{% endtable %}

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='multi-layer-ai-guardrails-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Remove the Redis Stack and AI PII Anonymizer containers:

```bash
docker rm -f redis-stack kong-pii-anonymizer
```
