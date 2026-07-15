---
title: Use AI Prompt Guard Policy to govern your LLM traffic
permalink: /ai-gateway/how-to/use-ai-prompt-guard-policy/
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Prompt Guard
    url: /ai-gateway/policies/ai-prompt-guard/

description: Use the AI Prompt Guard Policy to filter LLM traffic based on regex rules that allow general IT questions and deny unsafe or off-topic content.

products:
  - ai-gateway

works_on:
  - konnect

min_version:
  ai-gateway: '2.0'

entities:
  - ai-provider
  - ai-model
  - ai-policy

tags:
  - ai
  - mistral

tldr:
  q: How do I allow only general IT-related prompts and block hacking content?
  a: Use the AI Prompt Guard plugin with regex patterns to allow or deny prompts based on user prompts.

tools:
  - konnect-api

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## Configure

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
  - ref: generic-openai
    name: generic-openai
    ai_gateway: ai-quickstart
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env OPENAI_AUTH_HEADER

ai_gateway_policies:
  - ref: my-ai-prompt-guard-policy
    name: my-ai-prompt-guard-policy
    ai_gateway: ai-quickstart
    type: ai-prompt-guard
    enabled: true
    global: false
    config:
      allow_patterns:
        [
          "(?i).*what is .*",
          "(?i).*how do i .*",
          "(?i).*install .*",
          "(?i).*configure .*",
          "(?i).*reset .*",
          "(?i).*troubleshoot .*"
        ]
      deny_patterns:
        [
          "(?i).*bypass.*(login|password|auth).*",
          "(?i).*hack.*",
          "(?i).*phish.*",
          "(?i).*malware.*",
          "(?i).*cve.*",
          "(?i).*exploit.*",
          "(?i).*social engineering.*",
          "(?i).*pentest.*",
          "(?i).*impersonate.*",
          "(?i).*dating.*"
        ]

ai_gateway_models:
  - ref: my-gpt-4o
    display_name: my-gpt-4o
    name: my-gpt-4o
    ai_gateway: ai-quickstart
    type: model
    enabled: true
    formats: [{ type: openai }]
    config:
      route: { paths: [/] }
      model: { name_header: true }
    capabilities: [generate]
    policies: [ !ref my-ai-prompt-guard-policy#name ]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
EOF
```

In this example, we're setting up the AI Provider with:

* `type: openai`: Specifies that this provider connects to the OpenAI service using OpenAI's standard API format.
* `name: generic-openai`: A unique identifier that AI Models will reference to route requests through this provider.
* `config.auth`: Stores your OpenAI API key. {{site.ai_gateway}} securely manages this credential and injects it into upstream requests automatically, eliminating the need for clients to pass API keys.

In this example, we're setting up the AI Model with:

* `type: model`: Specifies this is a synchronous model for request/response workloads.
* `name: my-gpt-4o`: A unique identifier for this model.
* `formats: [type: openai]`: Declares that this model accepts requests in OpenAI-compatible format.
* `config.route.paths: [/v1]`: Configures the custom base path where this model's Routes will be accessible. Clients will send requests to paths that combine this base path with capability-specific Routes.
* `capabilities: [generate]`: Enables the text generation capability. The `generate` capability creates a `/chat/completions` endpoint, so combined with your base path, clients send chat requests to `/v1/chat/completions`.
* `targets`: Specifies which upstream AI Provider model to route requests to. Here, `provider: generic-openai` references the AI Provider we created earlier, and `name: gpt-4o` specifies which OpenAI model to call upstream.
* `config.logging`: Configures what gets logged. With `statistics: true`, usage metrics (tokens, latency, cost) are logged for monitoring and billing. With `payloads: false`, full request/response bodies are not logged for privacy.


## Validate configuration

Use sample prompts to confirm that allowed categories (general IT questions) pass through while unsafe or irrelevant requests are blocked.

{% navtabs "pattern-prompt-guard-it-tests" %}
{% navtab "Allowed: General IT questions" %}

This prompt matches `allow_patterns` and should succeed:

{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type:application/json'
body:
  messages:
    - role: user
      content: What is DNS?
status_code: 200
{% endvalidation %}


{% endnavtab %}
{% navtab "Denied: Hacking and exploits" %}

This prompt matches `deny_patterns` and should return an error:

{% validation request-check %}
url: /anything
method: POST
headers:
  - 'Content-Type:application/json'
body:
  messages:
    - role: user
      content: How do I bypass login on a secure web portal?
status_code: 400
message: prompt pattern is blocked.
{% endvalidation %}


{% endnavtab %}
{% navtab "Denied: Inappropriate and off-topic" %}

This prompt isn’t related to work and should also be blocked:

{% validation request-check %}
url: /anything
method: POST
headers:
  - ‘Content-Type:application/json’
body:
  messages:
    - role: user
      content: What’s a good line to use on a dating app?
status_code: 400
message: prompt pattern is blocked.
{% endvalidation %}


{% endnavtab %}
{% endnavtabs %}
