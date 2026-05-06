---
title: Guardrail Integrations
description: Integrate external guardrail services through Kong using dedicated Plugins and the universal custom guardrail adapter.
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
categories:
  - guardrails
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - ai-proxy-advanced
  - ai-azure-content-safety
  - ai-custom-guardrail
  - key-auth
requires_embeddings: false
extra_services:
  - name: Azure Content Safety
    env_vars: [DECK_AZURE_CONTENT_SAFETY_URL, DECK_AZURE_CONTENT_SAFETY_KEY]
    hint: "Create an Azure AI Content Safety resource and note the endpoint URL and API key."
  - name: Mistral Moderation
    env_vars: [DECK_MISTRAL_MODERATION_TOKEN]
    hint: "Get a Mistral API key from console.mistral.ai."

hint: You need an OpenAI API key, an Azure Content Safety resource (for the Azure tab), and a Mistral API key (for the Mistral tab).
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"      
      content: |
        This tutorial uses {{site.konnect_product_name}}. You will provision a recipe-scoped Control Plane and local Data Plane via the [quickstart script](https://get.konghq.com/quickstart), then claim the Control Plane for declarative management with kongctl.

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped control plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='guardrail-integrations-recipe'
           curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
           ```

           This provisions a Konnect Control Plane named `guardrail-integrations-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl + decK
      content: |
        This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
        2. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).

        You can verify both are installed:

        ```bash
        kongctl version
        deck version
        ```
    - title: OpenAI
      content: |
        This tutorial uses OpenAI as the LLM provider for all configurations:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Create a decK variable with the API key:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: Azure Content Safety
      content: |
        This tutorial uses Azure AI Content Safety (required for the Azure tab):

        1. [Create an Azure AI Content Safety resource](https://portal.azure.com/#create/Microsoft.CognitiveServicesContentSafety).
        1. Note the endpoint URL and API key from the resource's Keys and Endpoint page.
        1. Create decK variables:

           ```sh
           export DECK_AZURE_CONTENT_SAFETY_URL='https://YOUR-RESOURCE.cognitiveservices.azure.com'
           export DECK_AZURE_CONTENT_SAFETY_KEY='your-content-safety-key'
           ```
    - title: Mistral Moderation
      content: |
        This tutorial uses Mistral's moderation API (required for the Mistral tab):

        1. [Create a Mistral account](https://console.mistral.ai/).
        1. [Get an API key](https://console.mistral.ai/api-keys/).
        1. Create a decK variable:

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
  This recipe demonstrates how to integrate external guardrail services with {{site.ai_gateway_name}} using the [AI Custom Guardrail](/plugins/ai-custom-guardrail/) Plugin, introduced in Kong 3.14. The custom guardrail Plugin provides a single adaptable interface that works with any HTTP-based guardrail provider. You define the request format, write a short Lua function to parse the response, and the Plugin handles the rest.

  The Azure Content Safety tab shows the custom guardrail Plugin alongside the dedicated [AI Azure Content Safety](/plugins/ai-azure-content-safety/) Plugin so you can see the difference. The Mistral Moderation tab shows the custom guardrail integrating with a service that has no dedicated Kong Plugin, demonstrating why a universal adapter is the default approach going forward.
---

## The problem

The AI content safety landscape is fragmented and growing fast. Every major cloud provider and an increasing number of startups offer guardrail APIs, each with a different interface, auth mechanism, and response format.

- **New guardrail providers appear constantly.** Azure Content Safety, AWS Bedrock Guardrails, Mistral Moderation, Google Perspective, LakeraGuard, Pangea, and dozens of smaller providers all offer content moderation APIs. Every organization has a preferred vendor, often driven by existing cloud investments, compliance requirements, or specific detection capabilities. A team on Azure gravitates toward Azure Content Safety. A team using Mistral models wants Mistral's own moderation. An enterprise with custom compliance rules needs to call an internal endpoint. No single provider covers every organization's needs.

- **Each provider's API is different.** Azure Content Safety expects an `Ocp-Apim-Subscription-Key` header, a JSON body with `text` and `categories` fields, and returns severity scores from 0 to 6 per category. Mistral Moderation uses a Bearer token, accepts `model` and `input` fields, and returns boolean flags across categories like `sexual`, `hate_and_discrimination`, and `dangerous_and_criminal_content`. AWS Guardrails requires SigV4 request signing and returns structured policy violation objects. The auth, request format, and response parsing are all different, making it difficult to standardize guardrail enforcement at the gateway layer.

- **Organizations switch providers or run multiple simultaneously.** Compliance requirements change, better models appear, costs shift. A team that started with one provider's guardrails may need to migrate to another, or run two services in parallel during evaluation. Without a consistent integration pattern, each migration or addition requires new infrastructure, new parsing logic, and new operational knowledge.

## The solution

{{site.ai_gateway_name}} treats guardrail integration as a configuration problem rather than a code problem. Two capabilities anchor this recipe:

- **A universal HTTP adapter for content moderation.** Instead of waiting for a vendor-specific Plugin to ship for every new guardrail service, you describe the service's API in declarative configuration. The same adapter pattern serves Azure Content Safety, Mistral Moderation, internal compliance endpoints, or a custom ML model. When organizations switch providers or evaluate vendors in parallel, the change happens at the gateway layer, not in every application.

- **Consumer authentication on the guardrail Route.** The same Route that enforces guardrails identifies callers, so guardrail decisions and audit logs can be tied back to the specific consumer that triggered them. This recipe uses API key authentication on a single Consumer to keep the demo focused on the guardrail flow.

This recipe demonstrates the [AI Custom Guardrail](/plugins/ai-custom-guardrail/) Plugin (introduced in Kong 3.14) with two services, Azure Content Safety and Mistral Moderation, and includes the dedicated [AI Azure Content Safety](/plugins/ai-azure-content-safety/) Plugin for direct comparison. The custom guardrail Plugin is the recommended path going forward. Dedicated Plugins remain available for two cases: you are already running one on an earlier Gateway version, or the guardrail service requires authentication the custom adapter cannot perform (such as AWS SigV4 request signing).

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as {{site.ai_gateway_name}}
    participant G as Guardrail Service
    participant L as LLM Provider

    C->>K: POST /guardrail-integrations (apikey, prompt)
    activate K
    K->>K: key-auth — validate apikey, attach Consumer
    K->>G: ai-custom-guardrail — inspect content
    activate G
    G-->>K: Verdict (safe / unsafe)
    deactivate G
    alt Verdict: safe
        K->>K: ai-proxy-advanced — inject provider auth
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

<!-- vale off -->
{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: Client application
    responsibility: Sends OpenAI-format chat requests with an API key for Consumer identification
  - component: Kong, [key-auth](/plugins/key-auth/)
    responsibility: Identifies the Consumer and rejects requests without a valid API key
  - component: Kong, guardrail Plugin ([ai-azure-content-safety](/plugins/ai-azure-content-safety/) or [ai-custom-guardrail](/plugins/ai-custom-guardrail/))
    responsibility: Extracts text content and sends it to the external guardrail service for evaluation
  - component: External guardrail service
    responsibility: Analyzes content against safety policies and returns a verdict
  - component: Kong, [ai-proxy-advanced](/plugins/ai-proxy-advanced/)
    responsibility: Routes approved requests to the configured LLM provider
  - component: LLM provider
    responsibility: Processes the prompt and returns a completion
{% endtable %}
<!-- vale on -->

{:.info}
> **AWS SigV4 auth:** The AI Custom Guardrail Plugin supports HTTP-based authentication (API keys in headers, query parameters, or request body). AWS Bedrock Guardrails requires SigV4 request signing, which the custom Plugin does not support. Use the dedicated [AI AWS Guardrails](/plugins/ai-aws-guardrails/) Plugin for that service.

## How it works

When a request arrives at the `/guardrail-integrations` Route, Kong runs three Plugins in sequence before the request reaches the LLM provider:

1. The client sends `POST /guardrail-integrations` with an `apikey` header and an OpenAI-format chat body.
2. The [key-auth](/plugins/key-auth/) Plugin matches the `apikey` header against a registered Consumer credential. Unrecognized keys are rejected with `401`. Valid keys identify the caller for downstream Plugins and analytics.
3. The guardrail Plugin (either [ai-custom-guardrail](/plugins/ai-custom-guardrail/) or [ai-azure-content-safety](/plugins/ai-azure-content-safety/)) extracts text content from the chat messages, calls the external guardrail service, and evaluates the response. If the content fails the configured safety policy, the Plugin short-circuits the request with a `400` and a block reason. No LLM tokens are consumed.
4. If the content passes, [ai-proxy-advanced](/plugins/ai-proxy-advanced/) injects the provider credential, forwards the request to OpenAI, and normalizes the response back to OpenAI format.
5. For configurations that use `guarding_mode: BOTH`, the guardrail Plugin re-runs on the LLM response before it is returned to the client.

Plugin priority guarantees the order: [ai-custom-guardrail](/plugins/ai-custom-guardrail/) (priority 785), [ai-azure-content-safety](/plugins/ai-azure-content-safety/) (priority 774), and [ai-proxy-advanced](/plugins/ai-proxy-advanced/) (priority 770). Blocked content never reaches the LLM provider regardless of which guardrail Plugin you choose.

### Key Auth, Consumer identification

The [key-auth](/plugins/key-auth/) Plugin matches the `apikey` request header against a registered Consumer credential. Identifying the caller at the gateway layer means downstream Plugins, request logs, and Konnect Analytics all carry a Consumer name. For guardrails specifically, this lets you audit who triggered a block decision without needing application-side correlation.

#### Configuration details

```yaml
- name: key-auth
  config:
    key_names:
      - apikey
    hide_credentials: true
```
{:.no-copy-code}

**`key_names: [apikey]`**: The header (or query parameter) that carries the API key. Clients send `apikey: demo-api-key` in their request headers.

**`hide_credentials: true`**: Strips the `apikey` header before Kong forwards the request upstream. This prevents the Consumer credential from leaking to the LLM provider in proxied requests.

The recipe registers a single Consumer (`demo-app`) with one API key. Production deployments typically use multiple Consumers, often with [Consumer Groups](/gateway/entities/consumer-group/) to apply different policies per tier.

### AI Azure Content Safety, dedicated integration

The [AI Azure Content Safety](/plugins/ai-azure-content-safety/) Plugin is a dedicated integration available since Kong 3.7. It provides declarative configuration for Azure's content moderation API: specify the endpoint URL, API key, severity thresholds per category, and guarding mode. The Plugin handles request construction, response parsing, and block decisions internally. This recipe includes it for comparison with the custom guardrail approach. If you are already using this Plugin on an earlier Gateway version or need Azure managed identity authentication (which the custom guardrail Plugin does not support), the dedicated Plugin remains the right choice.

#### Configuration details

{%- raw %}
```yaml
- name: ai-azure-content-safety
  config:
    content_safety_url: ${{ env "DECK_AZURE_CONTENT_SAFETY_URL" }}
    content_safety_key: ${{ env "DECK_AZURE_CONTENT_SAFETY_KEY" }}
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

**`content_safety_url`**: The base URL of your Azure AI Content Safety resource. The Plugin appends the API path and version automatically.

**`content_safety_key`**: Your Azure API key. Alternatively, omit this field and set `use_azure_managed_identity: true` to authenticate using Azure managed identity. Managed identity support is the key advantage of the dedicated Plugin, removing the need to store and rotate API keys.

**`guarding_mode: INPUT`**: Inspects only the incoming request. Set to `BOTH` to also inspect the LLM response before returning it to the client.

**`categories`**: The list of content categories to evaluate and their rejection thresholds. Azure Content Safety scores each category from 0 (safe) to 6 (severe). A `rejection_level` of 2 blocks content rated 2 or higher on that category. Lower values are more strict.

**`output_type: FourSeverityLevels`**: Requests the four-level severity scale (0, 2, 4, 6) from Azure. The alternative `EightSeverityLevels` provides finer granularity (0 through 7).

**`reveal_failure_reason: true`**: Includes the category and severity details in the block response returned to the client. Set to `false` in production if you do not want to expose moderation details to end users.

**`stop_on_error: true`**: Rejects the request if the Azure Content Safety service is unreachable. Set to `false` to allow requests through when the guardrail service is down, accepting the content safety risk for availability.

See the full configuration reference at [ai-azure-content-safety](/plugins/ai-azure-content-safety/).

### AI Custom Guardrail, universal integration

The [AI Custom Guardrail](/plugins/ai-custom-guardrail/) Plugin is a universal adapter for any HTTP-based guardrail service. Instead of building provider-specific Plugins, you describe the guardrail service's API in configuration: what URL to call, what headers to send, how to construct the request body, and how to parse the response. The Plugin uses this description to make the guardrail call at request time. You write a short Lua function to interpret the response and decide whether to block. Any service with an HTTP API, whether a cloud moderation service, an internal compliance endpoint, or a custom ML model, can serve as a gateway-level guardrail.

The Plugin's configuration has four main sections: `params` for storing credentials and reusable values, `request` for defining the HTTP call, `functions` for writing response parsing logic, and `response` for mapping function return values to block decisions. Template variables connect these sections, letting you reference params in headers, inject content into the request body, and use function return values in the block decision.

#### Configuration details

##### Params, storing credentials and reusable values

The `config.params` section stores key-value pairs that you can reference elsewhere in the configuration using `$(conf.params.<KEY>)`. Values in this section support Kong Vault references, making them the correct place to store API keys, tokens, and other secrets.

In the Azure custom example, the API key is stored as a param:

{%- raw %}
```yaml
params:
  api_key: ${{ env "DECK_AZURE_CONTENT_SAFETY_KEY" }}
```
{% endraw -%}
{:.no-copy-code}

In the Mistral example, both the API key and the model name are stored:

{%- raw %}
```yaml
params:
  api_key: ${{ env "DECK_MISTRAL_MODERATION_TOKEN" }}
  model: mistral-moderation-2411
```
{% endraw -%}
{:.no-copy-code}

Any value you need to reference in headers, body, or functions should go in `params`.

##### Request, constructing the HTTP call

The `config.request` section defines the URL, headers, and body of the HTTP call to the guardrail service. Each field supports template variable substitution.

Azure custom guardrail request:

{%- raw %}
```yaml
request:
  url: ${{ env "DECK_AZURE_CONTENT_SAFETY_URL" }}/contentsafety/text:analyze?api-version=2023-10-01
  headers:
    Ocp-Apim-Subscription-Key: "$(conf.params.api_key)"
    Content-Type: application/json
  body:
    text: "$(content)"
    categories: "[\"Hate\",\"SelfHarm\",\"Sexual\",\"Violence\"]"
    outputType: "\"FourSeverityLevels\""
```
{% endraw -%}
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

The `url` field is the full URL of the guardrail API endpoint. For Azure, this includes the API path and query parameters. For Mistral, it is the standard moderation endpoint.

The `headers` section defines HTTP headers sent with the request. Use `$(conf.params.<KEY>)` to reference stored credentials. Notice how the Azure and Mistral APIs use different header names (`Ocp-Apim-Subscription-Key` vs `Authorization`) and formats (raw key vs Bearer token). The custom guardrail Plugin handles both through template substitution.

The `body` section defines the JSON request body. All values are strings. The `$(content)` variable is replaced with the extracted text from the chat messages (based on the `text_source` setting). For values that need to be JSON arrays or strings within the JSON body, you embed the JSON syntax in the string value. In the Azure example, `categories` is set to `"[\"Hate\",\"SelfHarm\",\"Sexual\",\"Violence\"]"` because Azure expects a JSON array, and `outputType` is `"\"FourSeverityLevels\""` because Azure expects a JSON string.

##### Functions, writing response parsing logic

The `config.functions` section contains named Lua functions that parse the guardrail service's response. Each function receives the deserialized JSON response body as its argument and must return a table of named values that can be referenced in the `response` section.

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

The key insight is that both functions follow the same pattern: iterate over the service-specific response structure, decide whether to block, and return a table with the decision and a message. The response format differences are entirely contained within the Lua function. The rest of the Plugin configuration does not need to know how the guardrail service structures its output.

##### Response, mapping function outputs to block decisions

The `config.response` section maps function return values to the Plugin's block decision.

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

The `block` field references a boolean value from a function's return table. When this value is `true`, the Plugin blocks the request. The `block_message` field references a string value that is returned to the client in the error response.

The template syntax is `$(<function_name>.<field_name>)`, where the function name matches a key in `config.functions` and the field name matches a key in the table returned by that function.

##### Template variable reference

<!-- vale off -->
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
    description: Access a value from `config.params`
  - variable: "`$(resp)`"
    description: Raw guardrail service response (used in functions)
  - variable: "`$(<function>.<field>)`"
    description: Access a field from a function's return table
{% endtable %}
<!-- vale on -->

### AI Proxy Advanced, LLM routing with secure-by-default fields

The [ai-proxy-advanced](/plugins/ai-proxy-advanced/) Plugin handles credential injection and LLM routing for approved requests. Two configuration fields are set explicitly to align with {{site.base_gateway}} 3.14's secure-by-default posture:

{%- raw %}
```yaml
- name: ai-proxy-advanced
  config:
    max_request_body_size: 1048576
    response_streaming: deny
    targets:
    - route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: ${{ env "DECK_OPENAI_TOKEN" }}
      logging:
        log_statistics: true
        log_payloads: true
      model:
        provider: openai
        name: ${{ env "DECK_CHAT_MODEL" }}
```
{% endraw -%}
{:.no-copy-code}

**`max_request_body_size: 1048576`**: Caps requests at 1 MB. Long system prompts and multi-turn conversation contexts can exceed the default body size, so this is set explicitly. Increase to `10485760` (10 MB) for RAG-heavy workloads.

**`response_streaming: deny`**: Disables Server-Sent Events streaming on this Route. The Mistral configuration uses `guarding_mode: BOTH`, which inspects the LLM response before returning it. Response inspection requires the full response body, so streaming is disabled to keep the recipe consistent across tabs.

For the full set of route types, providers, and balancer algorithms, see the [ai-proxy-advanced reference](/plugins/ai-proxy-advanced/).

### When to use a dedicated Plugin instead

The AI Custom Guardrail Plugin is the default approach for new guardrail integrations. Use a dedicated Plugin only when:

- **Complex auth is required.** AWS Bedrock Guardrails requires SigV4 request signing, which the custom guardrail Plugin does not support. Use [AI AWS Guardrails](/plugins/ai-aws-guardrails/).
- **You are already running a dedicated Plugin.** If you are using [AI Azure Content Safety](/plugins/ai-azure-content-safety/) on an earlier Gateway version (pre-3.14), there is no need to migrate immediately. The dedicated Plugin continues to work.
- **You need Azure managed identity.** The dedicated Azure Plugin supports managed identity authentication natively. The custom guardrail Plugin supports API keys and Bearer tokens but not Azure's managed identity flow.

### Production considerations

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/entities/vault/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables. The `config.params` section of the AI Custom Guardrail Plugin supports vault references directly.

## Apply the Kong configuration

The configuration below creates a {{site.base_gateway}} Service, Route, the Plugins described in [How it works](#how-it-works), and a single demo Consumer. The `select_tags` and kongctl `namespace` scope all resources to this recipe, enabling clean teardown and co-existence with other configurations on the same Control Plane.

This section runs in two parts. First, adopt the quickstart Control Plane into a kongctl namespace so the apply commands below can manage it:

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the Control Plane.

`KONNECT_CONTROL_PLANE_NAME` and `KONNECT_TOKEN` are exported once during the {{site.konnect_product_name}} prereq, and `DECK_OPENAI_TOKEN`, `DECK_AZURE_CONTENT_SAFETY_*`, and `DECK_MISTRAL_MODERATION_TOKEN` come from the credential prereqs. Each tab below exports only the model selection that varies per configuration.

{% navtabs "Guardrail Service" %}
{% tab Azure Content Safety %}

### Option 1: Dedicated AI Azure Content Safety Plugin

Export your environment variables:

```bash
export DECK_CHAT_MODEL='gpt-4o'  # or gpt-4o-mini, o3
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - guardrail-integrations-recipe
services:
- name: guardrail-integrations
  url: http://localhost
  routes:
  - name: guardrail-integrations
    paths:
    - /guardrail-integrations
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: guardrail-integrations-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: guardrail-integrations-proxy
    config:
      max_request_body_size: 1048576
      response_streaming: deny
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL" }}
  - name: ai-azure-content-safety
    instance_name: guardrail-integrations-azure-content-safety
    config:
      content_safety_url: ${{ env "DECK_AZURE_CONTENT_SAFETY_URL" }}
      content_safety_key: ${{ env "DECK_AZURE_CONTENT_SAFETY_KEY" }}
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
consumers:
- username: demo-app
  keyauth_credentials:
  - key: demo-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: guardrail-integrations-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

### Option 2: AI Custom Guardrail Plugin

Export your environment variables:

```bash
export DECK_CHAT_MODEL='gpt-4o'  # or gpt-4o-mini, o3
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - guardrail-integrations-recipe
services:
- name: guardrail-integrations
  url: http://localhost
  routes:
  - name: guardrail-integrations
    paths:
    - /guardrail-integrations
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: guardrail-integrations-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: guardrail-integrations-proxy
    config:
      max_request_body_size: 1048576
      response_streaming: deny
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL" }}
  - name: ai-custom-guardrail
    instance_name: guardrail-integrations-custom-azure
    config:
      guarding_mode: INPUT
      text_source: concatenate_user_content
      stop_on_error: true
      timeout: 10000
      params:
        api_key: ${{ env "DECK_AZURE_CONTENT_SAFETY_KEY" }}
      request:
        url: ${{ env "DECK_AZURE_CONTENT_SAFETY_URL" }}/contentsafety/text:analyze?api-version=2023-10-01
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
consumers:
- username: demo-app
  keyauth_credentials:
  - key: demo-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: guardrail-integrations-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% tab Mistral Moderation %}

Export your environment variables:

```bash
export DECK_CHAT_MODEL='gpt-4o'  # or gpt-4o-mini, o3
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - guardrail-integrations-recipe
services:
- name: guardrail-integrations
  url: http://localhost
  routes:
  - name: guardrail-integrations
    paths:
    - /guardrail-integrations
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: guardrail-integrations-auth
    config:
      key_names:
      - apikey
      hide_credentials: true
  - name: ai-proxy-advanced
    instance_name: guardrail-integrations-proxy
    config:
      max_request_body_size: 1048576
      response_streaming: deny
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: ${{ env "DECK_OPENAI_TOKEN" }}
        logging:
          log_statistics: true
          log_payloads: true
        model:
          provider: openai
          name: ${{ env "DECK_CHAT_MODEL" }}
  - name: ai-custom-guardrail
    instance_name: guardrail-integrations-custom-mistral
    config:
      guarding_mode: BOTH
      text_source: concatenate_all_content
      stop_on_error: true
      timeout: 10000
      params:
        api_key: ${{ env "DECK_MISTRAL_MODERATION_TOKEN" }}
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
consumers:
- username: demo-app
  keyauth_credentials:
  - key: demo-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: guardrail-integrations-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl sync -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endtab %}
{% endnavtabs %}

## Try it out

The demo script works with any of the configurations above. It sends four requests: a safe prompt that passes the guardrail, a harmful prompt that triggers content moderation, a borderline prompt that tests the guardrail's severity assessment, and a request with an invalid API key to demonstrate the auth boundary. The script uses the OpenAI SDK pointed at the Kong Route, so the client code is identical regardless of which guardrail service or approach you chose.

{:.info}

> The demo passes the API key via `default_headers` because the OpenAI SDK reserves `api_key` for the `Authorization: Bearer` header. To let clients pass the key through `api_key` directly, attach a [pre-function](/plugins/pre-function/) Plugin that copies the Bearer token to the `apikey` header server-side. See [Authenticate OpenAI SDK clients with Key Auth](/how-to/authenticate-openai-sdk-clients-with-key-auth/) for the pattern.

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
API_KEY = os.getenv("RECIPE_API_KEY", "demo-api-key")

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

1. **Safe request passed the guardrail.** The prompt "What are the benefits of renewable energy?" was sent to the guardrail service, which scored all categories below the rejection threshold. The request continued to the LLM proxy, which forwarded it to OpenAI and returned the response. The `proxy` latency (85ms) includes the guardrail service call. The `X-Kong-LLM-Model` header confirms which model served the request.

2. **Harmful content was blocked before reaching the LLM.** The prompt "Write detailed instructions for creating a dangerous weapon" triggered the Violence category in the guardrail service. The guardrail Plugin returned a `400` response with the block reason. The 92ms response time reflects only the guardrail service call. No LLM tokens were consumed.

3. **Borderline content passed the guardrail.** The prompt "Explain the history and impact of major global conflicts" discusses conflict in an academic context. The guardrail service scored it below the rejection threshold on all categories, so the request continued to the LLM. This demonstrates that the guardrail distinguishes between harmful instructions and legitimate discussion of sensitive topics.

4. **Invalid API key was rejected at the auth boundary.** The fourth request used a fake API key. The key-auth Plugin rejected the request with `401` before the guardrail or proxy Plugins ran. The request never reached the guardrail service or the LLM provider, so no tokens or guardrail quota were consumed. This confirms that consumer authentication is enforced before any expensive downstream call.

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

<!-- vale off -->
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
<!-- vale on -->

### Explore in Konnect

You can review the resources and traffic this recipe produced directly in [Konnect](https://cloud.konghq.com):

- Open **API Gateway → Gateways → guardrail-integrations-recipe** to see the Control Plane this recipe created.
- The **Routes** tab lists the `guardrail-integrations` Route. Open it and switch to the **Plugins** tab to see `key-auth`, `ai-proxy-advanced`, and your selected guardrail Plugin attached.
- The **Consumers** tab shows the `demo-app` Consumer along with its API key credential.
- The Gateway service's **Analytics** tab gives an at-a-glance view of the traffic the demo just generated, broken down by route and status code.
- For deeper analysis (token usage, latency percentiles, AI provider breakdown), open the **Observability** L1 menu in Konnect and filter by Control Plane.

## Cleanup

The recipe's `select_tags` and kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local Data Plane and delete the Control Plane from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='guardrail-integrations-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```

## Variations and next steps

**Add response-phase guardrails.** The Azure dedicated Plugin and the Mistral custom guardrail both support `guarding_mode: BOTH`, which inspects LLM responses before returning them to the client. The Mistral configuration in this recipe already uses `BOTH`. To add response guarding to the Azure configurations, change `guarding_mode` from `INPUT` to `BOTH` and re-apply.

**Integrate with additional guardrail services.** The AI Custom Guardrail Plugin works with any HTTP-based guardrail service. To add Google Perspective, for example, configure `config.request.url` to `https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze`, set the API key in `config.params`, and write a Lua function to parse Perspective's `attributeScores` response format. The same pattern applies to internal compliance endpoints or custom ML model servers.

**Combine with Kong's built-in guardrails.** External guardrail services complement Kong's built-in content safety Plugins. Stack the configurations from this recipe with regex filtering ([ai-prompt-guard](/plugins/ai-prompt-guard/)), semantic analysis ([ai-semantic-prompt-guard](/plugins/ai-semantic-prompt-guard/)), and PII protection ([ai-sanitizer](/plugins/ai-sanitizer/)) for defense-in-depth. See the [Multi-Layer AI Guardrails](/cookbooks/multi-layer-ai-guardrails/) recipe for a complete multi-layer example.

**Use AI AWS Guardrails for AWS Bedrock.** If your guardrail service is AWS Bedrock Guardrails, use the dedicated [AI AWS Guardrails](/plugins/ai-aws-guardrails/) Plugin. It handles SigV4 request signing natively, which the AI Custom Guardrail Plugin cannot do. Configure your guardrail ID and version in the Plugin config, and the Plugin manages the full AWS authentication flow.

**Use Kong Vaults for production credential management.** Replace the environment variable exports with vault references to store your Azure Content Safety API key, Mistral moderation token, and OpenAI API key securely. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the Konnect Config Store. See the [secrets management documentation](/gateway/entities/vault/) for setup instructions.
