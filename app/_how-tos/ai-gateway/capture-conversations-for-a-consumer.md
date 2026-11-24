---
title: Capture conversations for a consumer in {{site.ai_gateway}}
content_type: how_to
permalink: /ai-gateway/capture-conversations/
description: Turn on conversation capture and sample payloads for a single consumer, so you can read the prompts and responses behind a cost or behavior problem
published: false
automated_tests: false
products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl
  - konnect-api

min_version:
  ai-gateway: '2.4'

entities:
  - ai-model-provider
  - ai-model
  - ai-auth-strategy
  - ai-consumer

tags:
  - ai
  - observability
  - logging
  - cost-management

tldr:
  q: How do I capture the prompts and responses for a specific consumer in {{site.ai_gateway}}?
  a: |
    Turn on payload logging on the [AI Model](/ai-gateway/entities/ai-model/), then enable access log export and payload capture in the {{site.ai_gateway}} settings.
    Add a sampling rule such as `consumer.username == 'support-bot'` to capture conversations only for that consumer.

prereqs:
  inline:
    - title: OpenAI
      include_content: md/ai-gateway/v2/prereqs/openai
      icon_url: /assets/icons/openai.svg

cleanup:
  inline:
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway

related_resources:
  - text: Conversation capture
    url: /observability/conversation-capture/
  - text: AI Model entity reference
    url: /ai-gateway/entities/ai-model/
  - text: AI Auth Strategy entity reference
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: Analytics and debugging in {{site.ai_cost_management}}
    url: /ai-cost-management/analytics-and-debugging/
  - text: "{{site.ai_gateway}} logs"
    url: /ai-gateway/ai-logs/
---

<!-- TODO before publishing (speculative draft, nothing here is tested):
- min_version is 2.4 (see the release note in the reference page). Add a prereq for a data plane build that includes conversation capture.
- No RC exists yet, so none of this is tested. Sampling rule variable names: the examples use the ACL variable `consumer.username` from the spec, but the data plane code evaluates access log attributes (`kong.auth.consumer.username`). Run the PATCH and the validation against an RC and fix the rule.
- The settings endpoint is `x-internal` and `x-unstable` in the Konnect spec (platform-api PR 4020). Confirm it is public.
- Confirm that `consumer.username` is the AI Consumer name, and that the consumers endpoint accepts a name in the path.
- Replace the last sentence of Validate with the real check once the Konnect view of captured conversations is known, and state the expected delay.
  UI status as of 2026-11-20: no capture toggle or conversation view exists yet. KM-3635 (UI part, To Do) is blocked on KOKO-4869 (control plane API, In Progress) and AG-2227 (data plane, In Progress), with no design linked.
  Observability > Sessions exists in Konnect but is probably the separate Sessions feature (planned for the "Nov 26" release, docs issue #8115), not conversation capture. It has no consumer filter (only Status, Model, Gateway ID, User).
- Verify the Troubleshooting items against the data plane behavior.
- Write the tldr after testing. -->

Conversation capture exports each request's access log from the data plane to {{site.konnect_short_name}}, and can include the prompt and response.
Capturing every conversation exports a lot of data, much of it sensitive.
A sampling rule limits payload capture to one consumer, so you can read the prompts behind that consumer's cost spike or failing tool calls without capturing everyone else's.
For background, see [Conversation capture](/observability/conversation-capture/).

## Create an AI Auth Strategy, AI Model Provider, and AI Model

Create a key authentication [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/), an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) for OpenAI, and an [AI Model](/ai-gateway/entities/ai-model/) that uses both and logs payloads.

Payloads only reach the access log when the AI Model logs them, so `config.logging.payloads` must be `true`.
Conversation capture then decides which of those payloads are exported.

{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: support-bot-key-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: "Support bot key auth"
    name: support-bot-key-auth
    type: key-auth
    config:
      key_names: [apikey]
      key_in_header: true
      key_in_query: false
      hide_credentials: true
ai_gateway_model_providers:
  - ref: generic-openai
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: generic-openai
    display_name: "generic-openai"
    type: openai
    config:
      auth:
        type: basic
        headers:
        - name: Authorization
          value: !secret {source: !env OPENAI_AUTH_HEADER}
ai_gateway_models:
  - ref: support-chat
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: "Support chat"
    name: support-chat
    type: model
    enabled: true
    formats:
      - type: openai
    capabilities:
      - generate
    access:
      auth_strategies:
        - !ref support-bot-key-auth#name
    policies: []
    config:
      route:
        paths:
          - /v1
        model:
          body_param: model
          values:
            - support-chat
      logging:
        payloads: true
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
{% endentity_examples %}

{:.info}
> `!env AI_GATEWAY_ID` references the {{site.ai_gateway}} created by the quickstart script in the [prerequisites](#prerequisites), instead of creating a new one.

## Create the support-bot AI Consumer

Create an [AI Consumer](/ai-gateway/entities/ai-consumer/) named `support-bot`.
The sampling rule matches on this name, so the consumer name must be exactly `support-bot`.

{% entity_examples %}
ai_gateway_consumers:
  - ref: support-bot
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: "Support bot"
    name: support-bot
    type: api-key
    policies: []
{% endentity_examples %}

Fetch the UUID of the `support-bot` AI Consumer, which the credentials endpoint needs:

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/support-bot
status_code: 200
method: GET
headers:
  - 'Accept: application/json, application/problem+json'
capture:
  - variable: CONSUMER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

## Create an API key for the consumer

Create an API key credential for `support-bot` and capture it for later requests.

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$CONSUMER_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Support bot key
  name: support-bot-key
  type: api-key
extract_body:
  - name: 'api_key'
    variable: SUPPORT_BOT_API_KEY
capture:
  - variable: SUPPORT_BOT_API_KEY
    jq: ".api_key"
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> The response returns the generated `api_key` once, so the command stores it in `$SUPPORT_BOT_API_KEY` for the rest of this guide.

## Turn on conversation capture

Turn on access log export and payload capture, and limit payload capture to the `support-bot` consumer.
Payloads are part of the access log, so payload capture has an effect only when access log export is on.

<!--vale off-->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/settings
status_code: 200
method: PATCH
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  observability:
    access_logs:
      enabled: true
    payload_capture:
      enabled: true
      sampling_rule: "consumer.username == 'support-bot'"
{% endkonnect_api_request %}
<!--vale on-->

The data plane picks up the new settings the next time it syncs configuration from the control plane.

## Validate

Send a chat request as `support-bot`.
The sampling rule matches, so {{site.ai_gateway}} exports this conversation with its payload.
Requests from other consumers still produce an access log, but {{site.ai_gateway}} leaves out their prompts and responses.

<!--vale off-->
{% validation request-check %}
url: /v1/chat/completions
status_code: 200
method: POST
retry: true
headers:
  - 'Accept: application/json'
  - 'Content-Type: application/json'
  - 'apikey: $SUPPORT_BOT_API_KEY'
body:
  model: support-chat
  messages:
    - role: "user"
      content: "My order hasn't arrived. Can you help?"
{% endvalidation %}
<!--vale on-->

Then confirm that {{site.konnect_short_name}} captured the conversation with its prompt and response.
Captured conversations can take some time to appear.

## Troubleshooting

- **No payload for `support-bot`:** Check that the AI Model has `config.logging.payloads: true`, that `observability.payload_capture.enabled` is `true`, and that the sampling rule matches the consumer. A missing attribute evaluates to null and counts as no match.
- **No payloads at all after adding a rule:** If the sampling rule is invalid, the data plane captures no payloads. Check the data plane logs for `invalid payload capture sampling rule`.
- **Some conversations have no payload:** {{site.ai_gateway}} leaves out any body above the maximum payload size instead of truncating it.
- **Nothing is exported:** Conversation capture works with {{site.konnect_short_name}} data planes only, and the data plane needs `cluster_telemetry_endpoint` and its cluster certificate. Check the data plane logs for `[continuous-telemetry] exporter disabled`.
