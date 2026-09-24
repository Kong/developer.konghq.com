---
title: 'AI Routing Provider'
name: 'AI Routing Provider'

publisher: kong-inc

min_version:
  ai-gateway: '2.1'

works_on:
  - konnect

products:
  - ai-gateway

content_type: plugin

description: 'Delegate per-request LLM model selection to the NVIDIA Switchyard Decision API, dispatched natively as an {{site.ai_gateway}} custom policy.'

categories:
  - ai

tags:
  - ai
  - routing

search_aliases:
  - switchyard
  - nemo switchyard
  - nvidia nemo
  - model routing
  - llm routing
  - ai-routing-provider

related_resources:
  - text: NVIDIA Switchyard AI Routing plugin (classic {{site.base_gateway}})
    url: /plugins/ai-routing-provider/
  - text: NVIDIA NeMo Switchyard
    url: https://github.com/NVIDIA-NeMo/Switchyard
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: Custom policies
    url: /ai-gateway/custom-policies/

icon: nvidia.svg
---

The AI Routing Provider Policy is the {{site.ai_gateway}} 2.0 equivalent of the
[NVIDIA Switchyard AI Routing plugin](/plugins/ai-routing-provider/): it asks the NVIDIA
Switchyard Decision API which model should serve each request, then dispatches natively
to an [AI Model](/ai-gateway/entities/ai-model/) entity you've already configured on this
{{site.ai_gateway}}.
The decision service names a target.
{{site.ai_gateway}} decides what that name is allowed to mean.

This Policy resolves the selected target directly against your {{site.ai_gateway}}'s own AI
Model entities, and {{site.ai_gateway}}'s native routing takes over from there.
Unlike the classic {{site.base_gateway}} plugin, it doesn't need [AI Proxy Advanced](/plugins/ai-proxy-advanced/) in front of it.

This Policy runs the same `schema.lua` and `handler.lua` that back the
[NVIDIA Switchyard AI Routing plugin](/plugins/ai-routing-provider/), registered as a
**custom policy** rather than installed as a plugin.
See [Register the custom policy](#register-the-custom-policy) for how.

Benefits of using the AI Routing Provider Policy:

- **Native dispatch**: Routes directly to an AI Model entity instead of rewriting a model alias for another plugin to resolve.
- **Keep the gateway in control**: The decision service selects from a list of targets you configure. It can't introduce a model, a provider, or a URL that you didn't already authorize.
- **Keep prompts inside the gateway**: By default the Policy redacts every message before the decision request leaves {{site.ai_gateway}}, so routing costs you no prompt disclosure.
- **Fail open by default**: If the decision service is slow, down, or returns something unusable, traffic is still served by a configured default target.
- **Adopt it without risk**: The Policy starts in `observe_only`, where decisions are logged but never applied.

## How it works

The Policy runs in the access phase. It builds a decision request from the incoming
request, submits it to the Switchyard Decision API, and validates the returned
`selected.target` against its own `targets` map.

When [`config.dispatch`](/ai-gateway/policies/ai-routing-provider/reference/#schema--config-dispatch)
is set to `konnect_model`, a match resolves the target's `model` against this {{site.ai_gateway}}'s own
AI Model entities (by name, then by alias) and sets that model as the request's active model.
{{site.ai_gateway}} then proxies to whichever provider that AI Model is configured with.
On anything else, unknown target, drift, timeout, or error, the Policy falls back to
`default_target` and logs why.

<!--vale off-->
{% mermaid %}
sequenceDiagram
    autonumber
    participant Client
    participant Policy as AI Routing Provider
    participant Switchyard as NVIDIA Switchyard<br/>Decision API
    participant AIGW as {{site.ai_gateway}}<br/>native routing
    participant LLM

    Client->>Policy: Send AI request
    Policy->>Switchyard: POST /v1/decision
    Switchyard->>Policy: selected.target, selected.model

    alt Target is configured and the binding matches
        Policy->>AIGW: Set the resolved AI Model as active
    else Unknown target, drift, timeout, or error
        Policy->>AIGW: Use default_target, log the fallback
    end

    AIGW->>LLM: Forward to the selected model's provider
    LLM->>Client: Return response
{% endmermaid %}
<!--vale on-->

The decision service names a target. The Policy resolves that name against its own
configuration and this {{site.ai_gateway}}'s AI Model entities, and never accepts a URL or an
unlisted model from the response. For the full safety and prompt-disclosure model shared
with the classic plugin, see [How it works](/plugins/ai-routing-provider/#how-it-works) on
the {{site.base_gateway}} plugin page.

## Register the custom policy

The AI Routing Provider Policy is registered as a **streaming custom policy**: you upload the
plugin's `schema.lua` and `handler.lua` directly, and {{site.konnect_short_name}} distributes
and runs the handler for you, without a custom data plane image or a self-managed data plane.
See [Custom policies](/ai-gateway/custom-policies/) for the full deployment and lifecycle
mechanics shared by every custom policy.

Register it once per {{site.ai_gateway}}:

{% entity_example %}
type: custom_policy
data:
  name: ai-routing-provider
  type: streaming
  display_name: NVIDIA Switchyard AI Routing
  schema: ${schema}
  handler: ${handler}
variables:
  schema:
    value: $LUA_SCHEMA
    description: The `schema.lua` from the NVIDIA Switchyard AI Routing plugin.
  handler:
    value: $LUA_HANDLER
    description: The `handler.lua` from the NVIDIA Switchyard AI Routing plugin.
{% endentity_example %}

{:.info}
> **Note**: Data planes must be started with `KONG_CUSTOM_PLUGIN_STREAMING_ENABLED` to accept
> streamed custom policies.
> This registers the policy type once per {{site.ai_gateway}}. You still need to configure and
> attach an instance of it, in the next section.

## Configure the policy

After registering the custom policy type, attach and configure it the same way as any
other {{site.ai_gateway}} Policy, referencing it by the `name` you registered above:

{% entity_example %}
type: policy
data:
  display_name: AI Routing Provider
  name: ai-routing-provider
  type: ai-routing-provider
  config:
    decision_api_url: http://switchyard:4000/v1/decision
    decision_route: kong-router
    mode: observe_only
    dispatch: konnect_model
    default_target: weak
    prompt_disclosure: none
    timeout_ms: 2000
    targets:
      weak:
        model: z-ai/glm-5.3
        provider: openai
        protocol: openai_chat
        base_url: https://openrouter.ai/api/v1
      strong:
        model: google/gemini-3.8-flash
        provider: openai
        protocol: openai_chat
        base_url: https://openrouter.ai/api/v1

formats:
  - konnect-api
  - kongctl
{% endentity_example %}

Each `targets.*.model` must match the `name` or an alias of an
[AI Model](/ai-gateway/entities/ai-model/) entity already configured on this {{site.ai_gateway}}.
Start with `mode: observe_only` to see what the decision service would do without
changing behavior, then switch to `enforce`.

## Test the policy

Send a request and inspect the routing headers, the same way as the
[classic plugin](/plugins/ai-routing-provider/#test-the-plugin):

```bash
curl -i -X POST https://your-ai-gateway-endpoint/ai/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"router","messages":[{"role":"user","content":"Say hello."}]}'
```

A request that was routed by a decision returns `X-AI-Routing-Backend` and
`X-AI-Routing-Outcome` response headers. To confirm the gateway fails open, stop the
decision service and repeat the request: it should still return `200`, served by
`default_target`, with `X-AI-Routing-Outcome: fallback`.

## Limitations

- **This Policy shares its limitations with the classic {{site.base_gateway}} plugin.**
  See [Limitations](/plugins/ai-routing-provider/#limitations) on the plugin page for
  the full list (routing quality, no confidence score, no retry on the decision call).
- **`dispatch: model_alias` and `dispatch: upstream` don't apply here.** They target
  [AI Proxy Advanced](/plugins/ai-proxy-advanced/) or a Service's upstream directly,
  neither of which this Policy runs alongside. Use `dispatch: konnect_model`.
