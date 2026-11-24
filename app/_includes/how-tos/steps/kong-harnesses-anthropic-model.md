Create the following entities:

* An `openid-connect` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) that checks the Okta access token in the `Authorization` header.
* An [AI Model Provider](/ai-gateway/entities/ai-model-provider/) with your Anthropic key.
* An [AI Model](/ai-gateway/entities/ai-model/) for `claude-sonnet-5-5`, which {{ include.cli_name }} calls at `POST /v1/messages`.

{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: okta-oidc
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Okta OIDC
    name: okta-oidc
    type: openid-connect
    config:
      issuer: !env ISSUER_URL
      audience_required:
        - api://default
      auth_methods:
        - bearer
      bearer_token_param_type:
        - header
      hide_credentials: true
      upstream_access_token_header: null
      cache_tokens_salt: okta-oidc-cache-salt
ai_gateway_model_providers:
  - ref: anthropic
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Anthropic
    name: anthropic
    type: anthropic
    config:
      auth:
        type: basic
        headers:
          - name: x-api-key
            value: !secret {source: !env ANTHROPIC_API_KEY}
ai_gateway_models:
  - ref: claude-sonnet-5-5
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: claude-sonnet-5-5
    name: claude-sonnet-5-5
    type: model
    capabilities:
      - generate
    formats:
      - type: anthropic
    targets:
      - name: claude-sonnet-5-5
        provider: anthropic
        config:
          type: anthropic
    access:
      auth_strategies:
        - !ref okta-oidc#name
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - claude-sonnet-5-5
{% endentity_examples %}

When `upstream_access_token_header` is `null`, {{site.ai_gateway}} doesn't send the Okta access token to Anthropic and sends only your Anthropic key.
