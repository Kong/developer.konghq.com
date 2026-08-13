---
title: Use AI Prompt Guard Policy to govern your LLM traffic
permalink: /ai-gateway/use-ai-prompt-guard-policy/
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
  - ai-model-provider
  - ai-model
  - ai-policy

tags:
  - ai

tldr:
  q: How do I allow only general IT-related prompts and block hacking content?
  a: Use the AI Prompt Guard Policy with regex patterns to allow or deny prompts based on user prompts.

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

---

## Create the AI Model Provider, AI Model, and AI Prompt Guard Policy

Create both an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) and an [AI Model](/ai-gateway/entities/ai-model/) with a single `kongctl` apply command.

You'll also configure the [AI Prompt Guard Policy](/ai-gateway/policies/ai-prompt-guard/) to filter LLM traffic based on regex rules that allow general IT questions and deny unsafe or off-topic content.

{% entity_examples %}
ai_gateway_model_providers:
  - ref: generic-openai
    name: generic-openai
    ai_gateway: !lookup name:ai-quickstart
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
    ai_gateway: !lookup name:ai-quickstart
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
    ai_gateway: !lookup name:ai-quickstart
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
            - my-gpt-4o
    capabilities: [generate]
    policies: [ !ref my-ai-prompt-guard-policy#name ]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
{% endentity_examples %}

In this example, we're setting up the AI Prompt Guard Policy with:

* `type: ai-prompt-guard`: Specifies that this Policy filters requests by matching the user's prompt against allow and deny regex pattern lists.
* `global: false`: Scopes the Policy to only the AI Models it's explicitly attached to via `policies:`, rather than applying it to every resource on {{site.ai_gateway}}.
* `config.allow_patterns`: A list of regexes matched against the user's prompt. The request must match at least one of these to pass through, unless it's also blocked by `deny_patterns`.
* `config.deny_patterns`: A list of regexes matched against the user's prompt. A match here always rejects the request with a 400 response, even if the prompt also matches an `allow_patterns` entry. Deny always takes precedence over allow.
* `policies: [!ref my-ai-prompt-guard-policy#name]` on the AI Model: Attaches this Policy so it applies to every request routed through `my-gpt-4o`.


## Validate configuration

Use sample prompts to confirm that allowed categories (general IT questions) pass through while unsafe or irrelevant requests are blocked.

{% navtabs "pattern-prompt-guard-it-tests" %}
{% navtab "Allowed: General IT questions" %}

This prompt matches `allow_patterns` and should succeed:

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "What is DNS?"
         }
       ],
       "model": "my-gpt-4o"
     }'
```

{% endnavtab %}
{% navtab "Denied: Hacking and exploits" %}

This prompt matches `deny_patterns` and should return an error:

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "How to hack DNS?"
         }
       ],
       "model": "my-gpt-4o"
     }'
```


{% endnavtab %}
{% navtab "Denied: Inappropriate and off-topic" %}

This prompt isn’t related to work and should also be blocked:

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "What’s a good line to use on a dating app?"
         }
       ],
       "model": "my-gpt-4o"
     }'
```

{% endnavtab %}
{% endnavtabs %}