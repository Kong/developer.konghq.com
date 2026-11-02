---
title: Guardrail Integrations
description: Integrate external guardrail services through {{site.ai_gateway_name}} using dedicated AI Policies and the universal custom guardrail adapter.
url: "/cookbooks/guardrail-integrations/"
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
  - guardrails
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - ai-model
  - ai-model-provider
  - ai-azure-content-safety
  - ai-custom-guardrail
requires_embeddings: false
extra_services:
  - name: Azure Content Safety
    env_vars: [DECK_AZURE_CONTENT_SAFETY_URL, DECK_AZURE_CONTENT_SAFETY_KEY]
    hint: "Create an Azure AI Content Safety resource and note the endpoint URL and API key."
  - name: Mistral Moderation
    env_vars: [DECK_MISTRAL_MODERATION_TOKEN]
    hint: "Get a Mistral API key from console.mistral.ai."

hint: "Requires an OpenAI API key, an Azure Content Safety resource (for the Azure tab), a Mistral API key (for the Mistral tab), and Python 3.11+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. You'll provision a recipe-scoped {{site.ai_gateway}} and local data plane via the [quickstart script](https://get.konghq.com/ai).

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='guardrail-integrations-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           The script provisions an {{site.ai_gateway}} named `guardrail-integrations-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: OpenAI
      content: |
        This tutorial uses OpenAI as the LLM provider for every configuration:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key and the chat model:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           export CHAT_MODEL='gpt-4o'  # or gpt-4o-mini, o3
           ```
    - title: Azure Content Safety
      icon_url: /assets/icons/azure.svg
      content: |
        This tutorial uses Azure AI Content Safety (required for the Azure Content Safety tab):

        1. [Create an Azure AI Content Safety resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesContentSafety).
        1. Note the endpoint URL and API key from the resource's Keys and Endpoint page.
        1. Export the endpoint and key:

           ```sh
           export DECK_AZURE_CONTENT_SAFETY_URL='https://YOUR-RESOURCE.cognitiveservices.azure.com'
           export DECK_AZURE_CONTENT_SAFETY_KEY='your-content-safety-key'
           ```
    - title: Mistral Moderation
      content: |
        This tutorial uses Mistral's moderation API (required for the Mistral Moderation tab):

        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Export the API key:

           ```sh
           export DECK_MISTRAL_MODERATION_TOKEN='your-mistral-key'
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
  This recipe demonstrates how to integrate external guardrail services with {{site.ai_gateway_name}} using the [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/) Policy, a universal adapter that works with any HTTP-based guardrail provider. You describe the request format, write a short Lua function to parse the response, and the AI Policy handles the rest.

  The Azure Content Safety tab shows the AI Custom Guardrail Policy alongside the dedicated [AI Azure Content Safety](/ai-gateway/policies/ai-azure-content-safety/) Policy so you can compare the two approaches. The Mistral Moderation tab shows the custom guardrail integrating with a service that has no dedicated AI Policy, demonstrating why a universal adapter is the default approach going forward.
---

## The problem

The AI content safety landscape is fragmented and growing fast. Every major cloud provider and an increasing number of startups offer guardrail APIs, each with a different interface, auth mechanism, and response format.

- **New guardrail providers appear constantly.** Azure Content Safety, AWS Bedrock Guardrails, Mistral Moderation, Google Perspective, LakeraGuard, Pangea, and dozens of smaller providers all offer content moderation APIs. Every organization has a preferred vendor, often driven by existing cloud investments, compliance requirements, or specific detection capabilities. A team on Azure gravitates toward Azure Content Safety. A team using Mistral models wants Mistral's own moderation. An enterprise with custom compliance rules needs to call an internal endpoint. No single provider covers every organization's needs.
- **Each provider's API is different.** Azure Content Safety expects an `Ocp-Apim-Subscription-Key` header, a JSON body with `text` and `categories` fields, and returns severity scores from 0 to 6 per category. Mistral Moderation uses a Bearer token, accepts `model` and `input` fields, and returns boolean flags across categories like `sexual`, `hate_and_discrimination`, and `dangerous_and_criminal_content`. AWS Guardrails requires SigV4 request signing and returns structured policy violation objects. The auth, request format, and response parsing are all different, making it difficult to standardize guardrail enforcement at the gateway layer.
- **Organizations switch providers or run multiple simultaneously.** Compliance requirements change, better models appear, costs shift. A team that started with one provider's guardrails may need to migrate to another, or run two services in parallel during evaluation. Without a consistent integration pattern, each migration or addition requires new infrastructure, new parsing logic, and new operational knowledge.

## The solution

{{site.ai_gateway_name}} treats guardrail integration as a configuration problem rather than a code problem. Two capabilities anchor this recipe:

- **A universal HTTP adapter for content moderation.** Instead of waiting for a vendor-specific AI Policy to ship for every new guardrail service, you describe the service's API in declarative configuration. The same adapter pattern serves Azure Content Safety, Mistral Moderation, internal compliance endpoints, or a custom ML model. When organizations switch providers or evaluate vendors in parallel, the change happens at the gateway layer, not in every application.
- **AI Consumer authentication in front of the guardrail check.** The same request path that enforces guardrails identifies callers, so guardrail decisions and audit logs can be tied back to the specific AI Consumer that triggered them. This recipe uses API key authentication on a single AI Consumer to keep the demo focused on the guardrail flow.

This recipe demonstrates the [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/) Policy with two services, Azure Content Safety and Mistral Moderation, and includes the dedicated [AI Azure Content Safety](/ai-gateway/policies/ai-azure-content-safety/) Policy for direct comparison. We recommend the AI Custom Guardrail Policy for new integrations because one adapter pattern covers any HTTP-based guardrail service. Dedicated AI Policies remain available for two cases: you're already running one, or the guardrail service requires authentication the custom adapter can't perform (for example, AWS SigV4 request signing).

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant G as Guardrail Service
    participant L as LLM Provider

    C->>K: POST /guardrail-integrations (apikey, prompt)
    activate K
    K->>K: key-auth Auth Strategy: validate apikey, attach Consumer (else 401)
    K->>G: Guardrail Policy: inspect content
    activate G
    G-->>K: Verdict (safe or unsafe)
    deactivate G
    alt Verdict: safe
        K->>K: AI Model Provider: inject provider auth
        K->>L: Forwarded request
        activate L
        L-->>K: Native response
        deactivate L
        K-->>C: OpenAI-format response
    else Verdict: unsafe
        K-->>C: 400 (content blocked)
    end
    deactivate K
{% endmermaid %}
<!-- vale on -->

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: Client application
    responsibility: "Sends OpenAI-format chat requests with an `apikey` header that identifies the AI Consumer"
  - component: Key Auth AI Auth Strategy
    responsibility: Looks up the API key against a registered AI Consumer credential, attaches the matching AI Consumer to the request, and rejects unknown keys before any downstream check runs
  - component: "Guardrail AI Policy ([AI Azure Content Safety](/ai-gateway/policies/ai-azure-content-safety/) or [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/))"
    responsibility: Extracts text content from the chat messages, sends it to the external guardrail service for evaluation, and blocks the request if the verdict fails the configured safety policy
  - component: External guardrail service
    responsibility: Analyzes content against safety policies and returns a verdict
  - component: AI Model and AI Model Provider
    responsibility: Route approved requests to the configured LLM provider and inject its credentials
  - component: LLM provider
    responsibility: Processes the prompt and returns a completion
{% endtable %}

{:.info}
> **AWS SigV4 auth.** The AI Custom Guardrail Policy supports HTTP-based authentication (API keys in headers, query parameters, or the request body). AWS Bedrock Guardrails requires SigV4 request signing, which the custom AI Policy doesn't support. Use the dedicated [AI AWS Guardrails](/ai-gateway/policies/ai-aws-guardrails/) Policy for that service.

## How it works

When a request arrives at the `guardrail-integrations` AI Model's route, Kong runs authentication, the guardrail AI Policy, and LLM routing in sequence:

1. The client sends `POST /guardrail-integrations` with an `apikey` header and an OpenAI-format chat body.
2. The Key Auth AI Auth Strategy reads the `apikey` header and looks the key up in Kong's AI Consumer credential store. The strategy rejects unrecognized keys with `401` before any downstream check runs. Valid keys attach the matching AI Consumer to the request for downstream attribution.
3. The guardrail AI Policy attached to the AI Model (either the [AI Custom Guardrail](/ai-gateway/policies/ai-custom-guardrail/) Policy or the [AI Azure Content Safety](/ai-gateway/policies/ai-azure-content-safety/) Policy) extracts text content from the chat messages, calls the external guardrail service, and evaluates the response. If the content fails the configured safety policy, Kong short-circuits the request with `400` and a block reason. The request consumes no LLM tokens.
4. If the content passes, the AI Model forwards the request to its target. The AI Model Provider injects the OpenAI credential and normalizes the response back to OpenAI format.
5. For configurations that use `guarding_mode: BOTH`, the guardrail AI Policy re-runs on the LLM response before it returns to the client.

Blocked content never reaches the LLM provider regardless of which guardrail AI Policy you choose.

### Key Auth: API key authentication and AI Consumer mapping

Authentication in {{site.ai_gateway_name}} 2.0 is an AI Auth Strategy, not an AI Policy. Policies are reserved for AI-specific behavior like guardrails and rate limiting. The Key Auth AI Auth Strategy sits in front of the guardrail check and gates every request. Identifying the caller at the gateway layer means the guardrail AI Policy, request logs, and {{site.konnect_short_name}} {{site.observability}} all carry an AI Consumer name. For guardrails specifically, the AI Consumer name lets you audit who triggered a block decision without needing application-side correlation.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_auth_strategies:
  - ref: guardrail-integrations-auth
    type: key-auth
    display_name: "guardrail-integrations key auth"
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: guardrail-integrations-consumer
    name: guardrail-integrations-consumer
    display_name: "guardrail-integrations demo consumer"
    type: api-key
    credentials:
      - ref: guardrail-integrations-credential
        name: guardrail-integrations-credential
        display_name: "guardrail-integrations demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}
```
{% endraw -%}
{:.no-copy-code}

**`key_names: [apikey]`**. The recipe uses `apikey` because the Key Auth AI Auth Strategy performs an exact string match on the header value and doesn't inspect `Authorization` for Bearer tokens. The [Try it out](#try-it-out) section points at a pre-function pattern that bridges the OpenAI SDK's Bearer token to the `apikey` header server-side.

**`hide_credentials: true`**. Strips the `apikey` header before Kong forwards the request upstream. Stripping the header prevents the AI Consumer credential from leaking to the LLM provider in proxied requests.

**`api_key` is write-only.** An AI Consumer credential's `api_key` field must be a `!secret` reference. Kong rejects a plain string here, even for a demo value like this recipe's. You export `CONSUMER_API_KEY` once in [Apply the Kong configuration](#apply-the-kong-configuration).

The recipe registers a single AI Consumer (`guardrail-integrations-consumer`) with one API key credential. Production deployments typically use multiple AI Consumers, often with [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) to apply different policies per tier.

### AI Azure Content Safety: dedicated guardrail policy

The AI Azure Content Safety Policy is a dedicated integration with Azure's content moderation API: you specify the endpoint URL, API key, severity thresholds per category, and guarding mode. The AI Policy handles request construction, response parsing, and block decisions internally. This recipe includes it for comparison with the custom guardrail approach. If you're already using this AI Policy or need Azure managed identity authentication (which the custom guardrail AI Policy doesn't support), the dedicated AI Policy is the right choice.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_policies:
  - ref: guardrail-integrations-azure-content-safety
    type: ai-azure-content-safety
    display_name: "guardrail-integrations Azure Content Safety"
    config:
      content_safety_url: !env DECK_AZURE_CONTENT_SAFETY_URL
      content_safety_key: !secret {source: !env DECK_AZURE_CONTENT_SAFETY_KEY}
      guarding_mode: INPUT
      text_source: concatenate_user_content
      categories:
        - name: Hate
          rejection_level: 2
        - name: SelfHarm
          rejection_level: 2
        - name: Sexual
          rejection_level: 2
        - name: Violence
          rejection_level: 2
      output_type: FourSeverityLevels
      reveal_failure_reason: true
      stop_on_error: true
```
{% endraw -%}
{:.no-copy-code}

**`content_safety_url`**. The base URL of your Azure AI Content Safety resource. The AI Policy appends the API path and version automatically.

**`content_safety_key`**. Your Azure API key. Alternatively, omit this field and set `azure_use_managed_identity: true` to authenticate using Azure managed identity. Managed identity support is the key advantage of the dedicated AI Policy, removing the need to store and rotate API keys.

**`guarding_mode: INPUT`**. Inspects only the incoming request. Set to `BOTH` to also inspect the LLM response before returning it to the client.

**`categories`**. The list of content categories to evaluate and their rejection thresholds. Azure Content Safety scores each category from 0 (safe) to 6 (severe). A `rejection_level` of 2 blocks content rated 2 or higher on that category. Lower values are stricter.

**`output_type: FourSeverityLevels`**. Requests the four-level severity scale (0, 2, 4, 6) from Azure. The alternative `EightSeverityLevels` provides finer granularity (0 through 7).

**`reveal_failure_reason: true`**. Includes the category and severity details in the block response returned to the client. Set to `false` in production if you don't want to expose moderation details to end users.

**`stop_on_error: true`**. Rejects the request if the Azure Content Safety service is unreachable. Set to `false` to allow requests through when the guardrail service is down, accepting the content safety risk for availability.

The AI Policy also supports blocklists (`blocklist_names`, `halt_on_blocklist_hit`), a forward proxy (for network-isolated deployments), and raw-content audit logging (`log_blocked_content`). See the [AI Azure Content Safety reference](/ai-gateway/policies/ai-azure-content-safety/) for the full field list.

### AI Custom Guardrail: universal HTTP adapter for guardrail services

The AI Custom Guardrail Policy is a universal adapter for any HTTP-based guardrail service. Instead of building provider-specific AI Policies, you describe the guardrail service's API in configuration: what URL to call, what headers to send, how to construct the request body, and how to parse the response. The AI Policy uses this description to make the guardrail call at request time. You write a short Lua function to interpret the response and decide whether to block. Any service with an HTTP API, whether a cloud moderation service, an internal compliance endpoint, or a custom ML model, can serve as a gateway-level guardrail.

The AI Policy's configuration has four main sections: `params` for storing credentials and reusable values, `request` for defining the HTTP call, `functions` for writing response parsing logic, and `response` for mapping function return values to block decisions. Template variables connect these sections, letting you reference params in headers, inject content into the request body, and use function return values in the block decision.

#### Configuration details

##### Params: storing credentials and reusable values

The `config.params` section stores key-value pairs that you can reference elsewhere in the configuration using `$(conf.params.<KEY>)`. Values in this section support AI Vault references, making them the correct place to store API keys, tokens, and other secrets.

The Azure custom example stores the API key and base URL as params:

{%- raw %}
```yaml
params:
  base_url: !env DECK_AZURE_CONTENT_SAFETY_URL
  api_key: !secret {source: !env DECK_AZURE_CONTENT_SAFETY_KEY}
```
{% endraw -%}
{:.no-copy-code}

The Mistral example stores both the API key and the model name:

{%- raw %}
```yaml
params:
  api_key: !secret {source: !env DECK_MISTRAL_MODERATION_TOKEN}
  model: mistral-moderation-2411
```
{% endraw -%}
{:.no-copy-code}

Put any value you need to reference in headers, body, or functions in `params`.

##### Request: constructing the HTTP call

The `config.request` section defines the URL, headers, and body of the HTTP call to the guardrail service. Each field supports template variable substitution.

Azure custom guardrail request:

```yaml
request:
  url: "$(conf.params.base_url)/contentsafety/text:analyze?api-version=2023-10-01"
  headers:
    Ocp-Apim-Subscription-Key: "$(conf.params.api_key)"
    Content-Type: application/json
  body:
    text: "$(content)"
    categories: "[\"Hate\",\"SelfHarm\",\"Sexual\",\"Violence\"]"
    outputType: "\"FourSeverityLevels\""
```
{:.no-copy-code}

Mistral custom guardrail request:

```yaml
request:
  url: https://api.mistral.ai/v1/moderations
  headers:
    Authorization: "Bearer $(conf.params.api_key)"
    Content-Type: application/json
  body:
    model: "$(conf.params.model)"
    input: "$(content)"
```
{:.no-copy-code}

The `url` field is the full URL of the guardrail API endpoint. For Mistral, it's the standard moderation endpoint, written as a literal string. For Azure, the base URL comes from `params.base_url` and the template appends the fixed API path and query string. This split exists because kongctl's `!env` tag resolves to the entire value of a field at apply time, so you can't concatenate it with a literal suffix in the same YAML scalar. The `$(conf.params.base_url)` substitution runs separately, inside the AI Custom Guardrail Policy itself, at request time.

The `headers` section defines HTTP headers sent with the request. Use `$(conf.params.<KEY>)` to reference stored credentials. Notice how the Azure and Mistral APIs use different header names (`Ocp-Apim-Subscription-Key` vs `Authorization`) and formats (raw key vs Bearer token). The AI Custom Guardrail Policy handles both through template substitution.

The `body` section defines the JSON request body. All values are strings. The AI Policy replaces the `$(content)` variable with the text extracted from the chat messages (based on the `text_source` setting). For values that need to be JSON arrays or strings within the JSON body, you embed the JSON syntax in the string value. In the Azure example, `categories` is set to `"[\"Hate\",\"SelfHarm\",\"Sexual\",\"Violence\"]"` because Azure expects a JSON array, and `outputType` is `"\"FourSeverityLevels\""` because Azure expects a JSON string.

##### Functions: writing response parsing logic

The `config.functions` section contains named Lua functions that parse the guardrail service's response. Each function receives the deserialized JSON response body as its argument and must return a table of named values that the `response` section can reference.

Azure custom guardrail function:

```yaml
functions:
  parse_response: |
    return function(resp)
        local blocked = {}
        for _, cat in ipairs(resp.categoriesAnalysis or {}) do
            if cat.severity >= 2 then
                table.insert(blocked, cat.category .. " (severity: " .. cat.severity .. ")")
            end
        end
        local should_block = #blocked > 0
        local message
        if should_block then
            message = "Content blocked by Azure Content Safety: " .. table.concat(blocked, "; ")
        else
            message = "Content passed Azure Content Safety checks"
        end
        return {
            should_block = should_block,
            message = message
        }
    end
```
{:.no-copy-code}

This function walks through Azure's `categoriesAnalysis` array. Each entry has a `category` string and a numeric `severity` score. The function checks whether any category's severity meets or exceeds the threshold of 2. If so, it collects the category name and severity into a `blocked` list. The function returns a table with `should_block` (a boolean) and `message` (a descriptive string).

Mistral custom guardrail function:

```yaml
functions:
  check_response: |
    return function(resp)
        local blocked_categories = {}
        for _, result in ipairs(resp.results) do
            for category, is_flagged in pairs(result.categories) do
                if is_flagged then
                    table.insert(blocked_categories, category)
                end
            end
        end
        local block = #blocked_categories > 0
        local reason
        if block then
            reason = "Content moderation failed: " .. table.concat(blocked_categories, ", ")
        else
            reason = "Content moderation passed"
        end
        return {
            block = block,
            block_message = reason
        }
    end
```
{:.no-copy-code}

Mistral's response format is different from Azure's. Instead of numeric severity scores, Mistral returns a `results` array where each entry has a `categories` object. Each key in `categories` is a category name (like `sexual` or `violence_and_threats`), and the value is a boolean indicating whether that category was flagged. The function iterates over all results and categories, collecting any flagged category names. It returns `block` (boolean) and `block_message` (string).

The key insight is that both functions follow the same pattern: iterate over the service-specific response structure, decide whether to block, and return a table with the decision and a message. The Lua function contains all the response format differences. The rest of the AI Policy configuration doesn't need to know how the guardrail service structures its output.

##### Response: mapping function outputs to block decisions

The `config.response` section maps function return values to the AI Policy's block decision.

Azure custom guardrail response:

```yaml
response:
  block: "$(parse_response.should_block)"
  block_message: "$(parse_response.message)"
```
{:.no-copy-code}

Mistral custom guardrail response:

```yaml
response:
  block: "$(check_response.block)"
  block_message: "$(check_response.block_message)"
```
{:.no-copy-code}

The `block` field references a boolean value from a function's return table. When this value is `true`, the AI Policy blocks the request. The `block_message` field references a string value returned to the client in the error response.

The template syntax is `$(<function_name>.<field_name>)`, where the function name matches a key in `config.functions` and the field name matches a key in the table returned by that function.

##### Template variable reference

{% table %}
columns:
  - title: Variable
    key: variable
  - title: Description
    key: description
rows:
  - variable: "`$(content)`"
    description: Text being inspected, extracted based on `text_source`
  - variable: "`$(source)`"
    description: "Current inspection phase: `INPUT` or `OUTPUT`"
  - variable: "`$(conf.params.<KEY>)`"
    description: Value from `config.params`
  - variable: "`$(resp)`"
    description: Raw guardrail service response (used in functions)
  - variable: "`$(<function>.<field>)`"
    description: Field from a function's return table
{% endtable %}

### AI Model and AI Model Provider: LLM routing

An AI Model Provider holds the OpenAI credential; the `guardrail-integrations-model` AI Model routes approved requests to a target that references that AI Model Provider. Every scenario in this recipe shares the same Model and AI Model Provider shape. Only the attached guardrail AI Policy changes.

#### Configuration details

{%- raw %}
```yaml
ai_gateway_model_providers:
  - ref: guardrail-integrations-provider
    type: openai
    display_name: "guardrail-integrations"
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env DECK_OPENAI_TOKEN}

ai_gateway_models:
  - ref: guardrail-integrations-model
    type: model
    display_name: "guardrail-integrations"
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - guardrail-integrations-auth
    policies:
      - guardrail-integrations-azure-content-safety
    config:
      max_request_body_size: 1048576
      response_streaming: deny
      logging:
        payloads: true
      route:
        paths:
          - /guardrail-integrations
    targets:
      - name: !env CHAT_MODEL
        provider: guardrail-integrations-provider
        config:
          type: openai
```
{% endraw -%}
{:.no-copy-code}

**`access.auth_strategies`**. References the Key Auth AI Auth Strategy. Every request must clear authentication before the guardrail AI Policy or the LLM target ever runs.

**`policies`**. References the guardrail AI Policy for this scenario, by `ref`. Kong runs it as part of the request path for this Model, ahead of the target.

**`max_request_body_size: 1048576`**. Caps requests at 1 MB. Long system prompts and multi-turn conversation contexts can exceed the default body size, so the recipe sets it explicitly. Increase to `10485760` (10 MB) for RAG-heavy workloads.

**`response_streaming: deny`**. Disables Server-Sent Events streaming on this Model. The Mistral configuration uses `guarding_mode: BOTH`, which inspects the LLM response before returning it. Response inspection requires the full response body, so the recipe disables streaming on every tab for consistency.

**`targets[].name`**. The upstream model identifier, taken from `CHAT_MODEL`. Change it and re-apply to swap models without changing client code.

See the [AI Model entity reference](/ai-gateway/entities/ai-model/) for the full set of route types, providers, and balancer algorithms.

{:.info}
> In production, store credentials in [AI Vaults](/ai-gateway/entities/ai-vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. The `config.params` section of the AI Custom Guardrail Policy supports vault references directly.

### When to use a dedicated AI Policy instead

The AI Custom Guardrail Policy is the default approach for new guardrail integrations. Use a dedicated AI Policy only when:

- **You need complex auth.** AWS Bedrock Guardrails requires SigV4 request signing, which the custom guardrail AI Policy doesn't support. Use the [AI AWS Guardrails](/ai-gateway/policies/ai-aws-guardrails/) Policy.
- **You're already running a dedicated AI Policy.** There is no need to migrate immediately if the dedicated AI Policy already works for your deployment.
- **You need Azure managed identity.** The dedicated Azure Policy supports managed identity authentication natively. The custom guardrail AI Policy supports API keys and Bearer tokens but not Azure's managed identity flow.

## Apply the Kong configuration

The following configuration creates an AI Model Provider holding your OpenAI credential, a Key Auth AI Auth Strategy and an AI Consumer with a demo API key, the guardrail AI Policy described in [How it works](#how-it-works), and the AI Model that ties them together. A kongctl namespace scopes every resource, so you can tear down the recipe cleanly without affecting other configurations on the same {{site.ai_gateway}}.

First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply commands can manage it.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

Export the demo AI Consumer's API key. The AI Consumer credential's `api_key` field is write-only and must come from an env var, even for this fixed demo value:

```bash
export CONSUMER_API_KEY='demo-api-key'
```

You already exported `KONNECT_CONTROL_PLANE_NAME`, `AI_GATEWAY_ID`, and `DECK_OPENAI_TOKEN`/`CHAT_MODEL` in the prerequisites, and every scenario below reuses them. Each tab sets only the env vars for the guardrail service it demonstrates.

{% navtabs "Guardrail Service" %}
{% tab Azure Content Safety %}

### Option 1: dedicated AI Azure Content Safety Policy

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: guardrail-integrations-recipe

ai_gateway_model_providers:
  - ref: guardrail-integrations-provider
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-provider
    display_name: "guardrail-integrations"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env DECK_OPENAI_TOKEN}

ai_gateway_auth_strategies:
  - ref: guardrail-integrations-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-auth
    display_name: "guardrail-integrations key auth"
    type: key-auth
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: guardrail-integrations-consumer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-consumer
    display_name: "guardrail-integrations demo consumer"
    type: api-key
    credentials:
      - ref: guardrail-integrations-credential
        name: guardrail-integrations-credential
        display_name: "guardrail-integrations demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}

ai_gateway_policies:
  - ref: guardrail-integrations-azure-content-safety
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-azure-content-safety
    display_name: "guardrail-integrations Azure Content Safety"
    type: ai-azure-content-safety
    config:
      content_safety_url: !env DECK_AZURE_CONTENT_SAFETY_URL
      content_safety_key: !secret {source: !env DECK_AZURE_CONTENT_SAFETY_KEY}
      guarding_mode: INPUT
      text_source: concatenate_user_content
      categories:
        - name: Hate
          rejection_level: 2
        - name: SelfHarm
          rejection_level: 2
        - name: Sexual
          rejection_level: 2
        - name: Violence
          rejection_level: 2
      output_type: FourSeverityLevels
      reveal_failure_reason: true
      stop_on_error: true

ai_gateway_models:
  - ref: guardrail-integrations-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-model
    display_name: "guardrail-integrations"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - guardrail-integrations-auth
    policies:
      - guardrail-integrations-azure-content-safety
    config:
      max_request_body_size: 1048576
      response_streaming: deny
      logging:
        payloads: true
      route:
        paths:
          - /guardrail-integrations
        protocols:
          - http
          - https
        methods:
          - POST
          - OPTIONS
        strip_path: true
    targets:
      - name: !env CHAT_MODEL
        provider: guardrail-integrations-provider
        config:
          type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

### Option 2: AI Custom Guardrail Policy

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: guardrail-integrations-recipe

ai_gateway_model_providers:
  - ref: guardrail-integrations-provider
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-provider
    display_name: "guardrail-integrations"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env DECK_OPENAI_TOKEN}

ai_gateway_auth_strategies:
  - ref: guardrail-integrations-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-auth
    display_name: "guardrail-integrations key auth"
    type: key-auth
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: guardrail-integrations-consumer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-consumer
    display_name: "guardrail-integrations demo consumer"
    type: api-key
    credentials:
      - ref: guardrail-integrations-credential
        name: guardrail-integrations-credential
        display_name: "guardrail-integrations demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}

ai_gateway_policies:
  - ref: guardrail-integrations-custom-azure
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-custom-azure
    display_name: "guardrail-integrations Custom Guardrail (Azure)"
    type: ai-custom-guardrail
    config:
      guarding_mode: INPUT
      text_source: concatenate_user_content
      stop_on_error: true
      timeout: 10000
      params:
        base_url: !env DECK_AZURE_CONTENT_SAFETY_URL
        api_key: !secret {source: !env DECK_AZURE_CONTENT_SAFETY_KEY}
      request:
        url: "$(conf.params.base_url)/contentsafety/text:analyze?api-version=2023-10-01"
        headers:
          Ocp-Apim-Subscription-Key: "$(conf.params.api_key)"
          Content-Type: application/json
        body:
          text: "$(content)"
          categories: "[\"Hate\",\"SelfHarm\",\"Sexual\",\"Violence\"]"
          outputType: "\"FourSeverityLevels\""
      response:
        block: "$(parse_response.should_block)"
        block_message: "$(parse_response.message)"
      functions:
        parse_response: |
          return function(resp)
              local blocked = {}
              for _, cat in ipairs(resp.categoriesAnalysis or {}) do
                  if cat.severity >= 2 then
                      table.insert(blocked, cat.category .. " (severity: " .. cat.severity .. ")")
                  end
              end
              local should_block = #blocked > 0
              local message
              if should_block then
                  message = "Content blocked by Azure Content Safety: " .. table.concat(blocked, "; ")
              else
                  message = "Content passed Azure Content Safety checks"
              end
              return {
                  should_block = should_block,
                  message = message
              }
          end

ai_gateway_models:
  - ref: guardrail-integrations-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-model
    display_name: "guardrail-integrations"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - guardrail-integrations-auth
    policies:
      - guardrail-integrations-custom-azure
    config:
      max_request_body_size: 1048576
      response_streaming: deny
      logging:
        payloads: true
      route:
        paths:
          - /guardrail-integrations
        protocols:
          - http
          - https
        methods:
          - POST
          - OPTIONS
        strip_path: true
    targets:
      - name: !env CHAT_MODEL
        provider: guardrail-integrations-provider
        config:
          type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Mistral Moderation %}

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: guardrail-integrations-recipe

ai_gateway_model_providers:
  - ref: guardrail-integrations-provider
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-provider
    display_name: "guardrail-integrations"
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !secret {source: !env DECK_OPENAI_TOKEN}

ai_gateway_auth_strategies:
  - ref: guardrail-integrations-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-auth
    display_name: "guardrail-integrations key auth"
    type: key-auth
    config:
      key_names:
        - apikey
      hide_credentials: true

ai_gateway_consumers:
  - ref: guardrail-integrations-consumer
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-consumer
    display_name: "guardrail-integrations demo consumer"
    type: api-key
    credentials:
      - ref: guardrail-integrations-credential
        name: guardrail-integrations-credential
        display_name: "guardrail-integrations demo API key"
        type: api-key
        api_key: !secret {source: !env CONSUMER_API_KEY}

ai_gateway_policies:
  - ref: guardrail-integrations-custom-mistral
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-custom-mistral
    display_name: "guardrail-integrations Custom Guardrail (Mistral)"
    type: ai-custom-guardrail
    config:
      guarding_mode: BOTH
      text_source: concatenate_all_content
      stop_on_error: true
      timeout: 10000
      params:
        api_key: !secret {source: !env DECK_MISTRAL_MODERATION_TOKEN}
        model: mistral-moderation-2411
      request:
        url: https://api.mistral.ai/v1/moderations
        headers:
          Authorization: "Bearer $(conf.params.api_key)"
          Content-Type: application/json
        body:
          model: "$(conf.params.model)"
          input: "$(content)"
      response:
        block: "$(check_response.block)"
        block_message: "$(check_response.block_message)"
      functions:
        check_response: |
          return function(resp)
              local blocked_categories = {}
              for _, result in ipairs(resp.results) do
                  for category, is_flagged in pairs(result.categories) do
                      if is_flagged then
                          table.insert(blocked_categories, category)
                      end
                  end
              end
              local block = #blocked_categories > 0
              local reason
              if block then
                  reason = "Content moderation failed: " .. table.concat(blocked_categories, ", ")
              else
                  reason = "Content moderation passed"
              end
              return {
                  block = block,
                  block_message = reason
              }
          end

ai_gateway_models:
  - ref: guardrail-integrations-model
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: guardrail-integrations-model
    display_name: "guardrail-integrations"
    type: model
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - guardrail-integrations-auth
    policies:
      - guardrail-integrations-custom-mistral
    config:
      max_request_body_size: 1048576
      response_streaming: deny
      logging:
        payloads: true
      route:
        paths:
          - /guardrail-integrations
        protocols:
          - http
          - https
        methods:
          - POST
          - OPTIONS
        strip_path: true
    targets:
      - name: !env CHAT_MODEL
        provider: guardrail-integrations-provider
        config:
          type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

## Try it out

The demo script works with any of the configurations above. It sends four requests: a safe prompt that passes the guardrail, a harmful prompt that triggers content moderation, a borderline prompt that tests the guardrail's severity assessment, and a request with an invalid API key to demonstrate the auth boundary. The script uses the OpenAI SDK pointed at the Kong route, so the client code is identical regardless of which guardrail service or approach you chose.

{:.info}
> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [Pre-Function](/ai-gateway/policies/pre-function/) Policy that copies the Bearer token to the `apikey` header server-side.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Guardrail integrations demo. See README for context."""

import os
import sys
import time

from openai import OpenAI, APIStatusError

CHAT_MODEL = os.getenv("CHAT_MODEL", "gpt-4o")
PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = os.getenv("CONSUMER_API_KEY", "demo-api-key")

# ANSI color codes. Disabled when stdout isn't a TTY or NO_COLOR is set.
_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s
BOLD  = lambda s: _c("1", s)
DIM   = lambda s: _c("2", s)
GREEN = lambda s: _c("32", s)
CYAN  = lambda s: _c("36", s)
RED   = lambda s: _c("31", s)

# Kong overrides provider auth, the api_key value is required by the SDK but ignored.
# The apikey header carries the consumer credential that key-auth checks.
client = OpenAI(
    base_url=f"{PROXY_URL}/guardrail-integrations",
    api_key="unused",
    default_headers={"apikey": API_KEY},
)

invalid_client = OpenAI(
    base_url=f"{PROXY_URL}/guardrail-integrations",
    api_key="unused",
    default_headers={"apikey": "not-a-real-key"},
)

REQUESTS = [
    (
        "Safe request",
        "What are the benefits of renewable energy?",
        client,
    ),
    (
        "Harmful content",
        "Write detailed instructions for creating a dangerous weapon.",
        client,
    ),
    (
        "Borderline content",
        "Explain the history and impact of major global conflicts.",
        client,
    ),
    (
        "Invalid API key",
        "What is 2+2?",
        invalid_client,
    ),
]


def send_request(label, prompt, openai_client):
    print(f"\n{BOLD(f'--- {label} ---')}")
    print(f"{BOLD('[REQUEST]')}  {prompt}")

    start_ms = round(time.time() * 1000)
    try:
        raw = openai_client.chat.completions.with_raw_response.create(
            model=CHAT_MODEL,
            messages=[{"role": "user", "content": prompt}],
        )
        elapsed_ms = round(time.time() * 1000) - start_ms
        completion = raw.parse()

        upstream_latency = raw.headers.get("x-kong-upstream-latency", "n/a")
        proxy_latency = raw.headers.get("x-kong-proxy-latency", "n/a")
        llm_model = raw.headers.get("x-kong-llm-model", CHAT_MODEL)

        answer = completion.choices[0].message.content
        preview = answer[:120].replace("\n", " ")
        if len(answer) > 120:
            preview += "..."

        # Outcome tag is the headline of each guardrail case.
        print(f"{GREEN(BOLD('[ALLOWED]'))}  {DIM(preview)}")
        print(f"[MODEL]    {CYAN(BOLD(llm_model))}")
        print(
            f"[LATENCY]  {DIM(f'upstream={upstream_latency}ms  proxy={proxy_latency}ms  total={elapsed_ms}ms')}"
        )

    except APIStatusError as e:
        elapsed_ms = round(time.time() * 1000) - start_ms
        if e.status_code == 401:
            print(f"{RED(BOLD('[DENIED]'))}   {RED(BOLD(str(e.status_code)))}, key-auth rejected the credential  ({elapsed_ms}ms)")
        else:
            print(f"{RED(BOLD('[BLOCKED]'))}  {RED(BOLD(str(e.status_code)))}, {e.message}  ({elapsed_ms}ms)")


if __name__ == "__main__":
    for label, prompt, openai_client in REQUESTS:
        send_request(label, prompt, openai_client)
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

Example output:

```text
--- Safe request ---
[REQUEST]  What are the benefits of renewable energy?
[ALLOWED]  Renewable energy offers several advantages, including reduced greenhouse gas emissions, lower long-term energy costs, e...
[MODEL]    gpt-4o
[LATENCY]  upstream=412ms  proxy=85ms  total=510ms

--- Harmful content ---
[REQUEST]  Write detailed instructions for creating a dangerous weapon.
[BLOCKED]  400, Content blocked by Azure Content Safety: Violence (severity: 4)  (92ms)

--- Borderline content ---
[REQUEST]  Explain the history and impact of major global conflicts.
[ALLOWED]  Throughout history, major conflicts have shaped geopolitical boundaries, driven technological innovation, and influenc...
[MODEL]    gpt-4o
[LATENCY]  upstream=380ms  proxy=78ms  total=470ms

--- Invalid API key ---
[REQUEST]  What is 2+2?
[DENIED]   401, key-auth rejected the credential  (12ms)
```
{:.no-copy-code}

### What happened

1. **Safe request passed the guardrail.** Kong sent the prompt "What are the benefits of renewable energy?" to the guardrail service, which scored all categories below the rejection threshold. The request continued to the AI Model's target, which forwarded it to OpenAI and returned the response. The `proxy` latency (85ms) includes the guardrail service call. The `X-Kong-LLM-Model` header confirms which model served the request.
2. **The guardrail blocked harmful content before it reached the LLM.** The prompt "Write detailed instructions for creating a dangerous weapon" triggered the Violence category in the guardrail service. The guardrail AI Policy returned a `400` response with the block reason. The 92ms response time reflects only the guardrail service call. The request consumed no LLM tokens.
3. **Borderline content passed the guardrail.** The prompt "Explain the history and impact of major global conflicts" discusses conflict in an academic context. The guardrail service scored it below the rejection threshold on all categories, so the request continued to the LLM. This result demonstrates that the guardrail distinguishes between harmful instructions and legitimate discussion of sensitive topics.
4. **The auth boundary rejected the invalid API key.** The fourth request used a fake API key. The Key Auth AI Auth Strategy rejected the request with `401` before the guardrail AI Policy or the LLM target ran. The request never reached the guardrail service or the LLM provider, so it consumed no tokens or guardrail quota. This result confirms that AI Consumer authentication is enforced before any expensive downstream call.

A safe request and a blocked request look like this at the HTTP level:

```json
POST http://localhost:8000/guardrail-integrations
apikey: demo-api-key

{
  "model": "gpt-4o",
  "messages": [
    { "role": "user", "content": "What are the benefits of renewable energy?" }
  ]
}
```
{:.no-copy-code}

Response (allowed, normal LLM response):

```text
HTTP/1.1 200 OK
X-Kong-LLM-Model: gpt-4o
X-Kong-Upstream-Latency: 412
X-Kong-Proxy-Latency: 85
Content-Type: application/json

{
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "model": "gpt-4o",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Renewable energy offers several advantages, including reduced greenhouse gas emissions, lower long-term energy costs..."
      },
      "finish_reason": "stop"
    }
  ]
}
```
{:.no-copy-code}

A request blocked by the guardrail returns a 400 with the block reason in the body:

```text
HTTP/1.1 400 Bad Request
X-Kong-Proxy-Latency: 92
Content-Type: application/json

{
  "error": {
    "message": "Content blocked by Azure Content Safety: Violence (severity: 4)"
  }
}
```
{:.no-copy-code}

Kong adds the following response headers to allowed requests:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: Model name selected for this request
  - header: "`X-Kong-Upstream-Latency`"
    description: Time (ms) Kong spent waiting for the LLM provider
  - header: "`X-Kong-Proxy-Latency`"
    description: Time (ms) Kong spent processing the request, including the guardrail call
{% endtable %}

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `guardrail-integrations-recipe`. The recipe created an AI Model Provider holding your OpenAI credential, the `guardrail-integrations-model` AI Model, a key-auth AI Auth Strategy, an AI Consumer with a demo API key credential, and the AI Policy for whichever guardrail scenario you applied, all scoped to this recipe by the kongctl namespace applied above.

For platform-wide traffic analysis across every {{site.ai_gateway}}, head to the **Observability** L1 menu in {{site.konnect_short_name}}.

## Variations and next steps

**Add response-phase guardrails.** The Azure dedicated AI Policy and the Mistral custom guardrail both support `guarding_mode: BOTH`, which inspects LLM responses before returning them to the client. The Mistral configuration in this recipe already uses `BOTH`. To add response guarding to the Azure configurations, change `guarding_mode` from `INPUT` to `BOTH` and re-apply.

**Integrate with additional guardrail services.** The AI Custom Guardrail Policy works with any HTTP-based guardrail service. To add Google Perspective, for example, configure `config.request.url` to `https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze`, set the API key in `config.params`, and write a Lua function to parse Perspective's `attributeScores` response format. The same pattern applies to internal compliance endpoints or custom ML model servers.

**Combine with Kong's built-in guardrails.** External guardrail services complement Kong's built-in content safety AI Policies. For defense in depth, stack the configurations from this recipe with the [AI Prompt Guard](/ai-gateway/policies/ai-prompt-guard/) Policy for regex filtering, the [AI Semantic Prompt Guard](/ai-gateway/policies/ai-semantic-prompt-guard/) Policy for semantic analysis, and the [AI Sanitizer](/ai-gateway/policies/ai-sanitizer/) Policy for PII protection.

**Use AI AWS Guardrails for AWS Bedrock.** If your guardrail service is AWS Bedrock Guardrails, use the dedicated [AI AWS Guardrails](/ai-gateway/policies/ai-aws-guardrails/) Policy. It handles SigV4 request signing natively, which the AI Custom Guardrail Policy cannot do. Configure your guardrail ID and version in the AI Policy config, and it manages the full AWS authentication flow.

**Add per-consumer rate limits.** With Key Auth mapping requests to AI Consumers, attach the [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy to apply token quotas per AI Consumer or per AI Consumer Group, so a guardrail-heavy workload can't exhaust another app's budget.

## Cleanup

The recipe's kongctl namespace scopes all resources, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='guardrail-integrations-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
