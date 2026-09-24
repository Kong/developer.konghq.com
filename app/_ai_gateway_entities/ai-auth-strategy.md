---
title: AI Auth Strategies
content_type: reference
entities:
  - ai-auth-strategy
products:
  - ai-gateway
min_version:
  ai-gateway: '2.0'
permalink: /ai-gateway/entities/ai-auth-strategy/
breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/entities/
description: Configure inbound AI Consumer authentication for AI Models, AI Agents, and AI MCP Servers in {{site.ai_gateway}}.
schema:
  api: konnect/ai-gateway
  path: /schemas/AIGatewayAuthStrategy
works_on:
  - konnect
tools:
  - konnect-api
  - kongctl
related_resources:
  - text: "About {{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Model Provider entity
    url: /ai-gateway/entities/ai-model-provider/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
  - text: Set up a {{site.identity}} auth server for AI Agent authentication
    url: /ai-gateway/set-up-kong-identity-for-a2a/
  - text: Enforce tiered AI budgets on AI Models with {{site.identity}}
    url: /ai-gateway/enforce-tiered-ai-budgets-with-kong-identity/
  - text: OpenID Connect authentication with {{site.ai_gateway}} 2.0
    url: /ai-gateway/openid-connect/
faqs:
  - q: What is the difference between an AI Auth Strategy and an AI Model Provider?
    a: |
      An AI Auth Strategy manages inbound authentication: it validates the credentials that AI Consumers
      present when calling an AI Model. An AI Model Provider manages outbound credentials: the secrets
      {{site.ai_gateway}} uses to authenticate to an upstream LLM service on behalf of the AI Consumer.

  - q: Can an AI Model use both key-auth and OIDC authentication at the same time?
    a: |
      Yes. An AI Model supports one `key-auth` AI Auth Strategy and one `openid-connect`
      AI Auth Strategy simultaneously. An AI Consumer's request is authenticated
      if it satisfies either strategy. Attaching an authentication AI Policy directly to an AI
      Model's `policies` field isn't supported; AI Auth Strategies are the only supported way
      to authenticate AI Model traffic.

  - q: Can an AI Agent use an AI Auth Strategy too?
    a: |
      Yes. Reference an AI Auth Strategy by `name` or `id` in the AI Agent's `access.auth_strategies`
      array, the same field used on AI Models. An AI Agent currently accepts up to one AI Auth Strategy
      reference. Attaching an authentication AI Policy directly to an AI Agent's `policies` field isn't
      supported; AI Auth Strategies are the only supported way to authenticate AI Agent traffic.

  - q: Can an AI MCP Server use an AI Auth Strategy too?
    a: |
      Yes, for `conversion-listener`, `listener`, and `passthrough-listener` AI MCP Servers. Reference an AI
      Auth Strategy by `name` or `id` in the AI MCP Server's `access.auth_strategies` array. An AI MCP
      Server currently accepts up to one AI Auth Strategy reference. `upstream-server` AI MCP Servers
      authenticate to their upstream separately, through `config.server.tools_list_auth`, and
      `conversion-only` AI MCP Servers have no `access` field since they never accept incoming MCP traffic
      directly. As with AI Agents, attaching an authentication AI Policy directly to an AI MCP Server's
      `policies` field isn't supported.

  - q: What happens when a request carries no valid credentials?
    a: |
      By default, {{site.ai_gateway}} routes it to a shared anonymous AI Consumer, which automatically is configured with a
      Request Termination policy that returns `401 Unauthorized` before the request reaches
      the AI Model, AI Agent, or AI MCP Server. This is set up automatically when you attach the
      AI Auth Strategy. See [Default termination behavior](#default-termination-behavior) for more information.

  - q: Can I reuse the same AI Auth Strategy across multiple AI Models, AI Agents, or AI MCP Servers?
    a: |
      Yes. Create an AI Auth Strategy once and reference it by `name` or `id` in the
      `access.auth_strategies` array of any AI Model, AI Agent, or AI MCP Server in the same gateway.

  - q: Which OIDC flows does the openid-connect type support?
    a: |
      By default, bearer token and client credentials flows are enabled. The full set includes
      `authorization_code`, `bearer`, `client_credentials`, `introspection`, `kong_oauth2`,
      `password`, `refresh_token`, `session`, and `userinfo`. Configure which flows are active
      with `config.auth_methods`.
---

## What is an AI Auth Strategy?

Your [AI Models](/ai-gateway/entities/ai-model/), [AI Agents](/ai-gateway/entities/ai-agent/), and [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/) often need access control: some teams should reach certain AI Models, AI Agents, or AI MCP Servers and others should not, and you need a way to verify who is calling before a request consumes tokens or touches sensitive data. An AI Auth Strategy lets you declare an inbound authentication mechanism at the gateway level and attach it to specific AI Models, AI Agents, or AI MCP Servers.

Use AI Auth Strategies to:
* Authenticate API keys and map them to [AI Consumers](/ai-gateway/entities/ai-consumer/)
* Authenticate enterprise users through an existing identity provider (Okta, Azure AD, Google, or any OIDC-compliant IdP) without managing keys manually
* Apply different authentication to different models, agents, or MCP servers. For example, API keys for internal automation and OIDC bearer tokens for user-facing applications.

An AI Auth Strategy manages inbound authentication, which is distinct from the outbound credentials managed by an [AI Model Provider](/ai-gateway/entities/ai-model-provider/). When an AI Consumer calls an AI Model, AI Agent, or AI MCP Server, the AI Auth Strategy checks who they are. The AI Model then uses the AI Model Provider's credentials to forward the request upstream; an AI Agent proxies the now-authenticated request directly to its upstream agent; an AI MCP Server uses the resolved identity for [ACL tool control](/ai-gateway/entities/ai-mcp-server/#acl-tool-control) before forwarding MCP traffic.

The following diagram shows where authentication fits in the request pipeline:

{% mermaid %}
flowchart LR
    Client["AI Consumer"]
    KeyAuth["Key Auth"]
    OIDC["OpenID Connect"]
    Decision{Auth?}
    AnonErr["Request Terminating w/ 401"]
    Select["AI Model, AI Agent, or<br/>AI MCP Server selection"]
    ACLs["ACLs"]
    Allowed["AI Model A, AI Agent A,<br/>AI MCP Server A"]
    Denied["AI Model B, AI Agent B,<br/>AI MCP Server B"]

    Client-->KeyAuth
    KeyAuth-->OIDC
    OIDC-->Decision
    Decision-->|no auth|AnonErr
    Decision-->|auth|Select
    Select-->|selects entity|ACLs
    ACLs-->|allowed|Allowed
    ACLs-->|denied|Denied
{% endmermaid %}

Authentication behaves like any other Kong plugin: it runs after route selection, in the context of the matched route, but before the AI Model, AI Agent, or AI MCP Server is selected. This means unauthenticated requests never reach that selection step or its policy evaluation.

{:.info}
> This diagram shows the general `key-auth`/`openid-connect` check. For an AI MCP Server with [`access.metadata`](/ai-gateway/entities/ai-mcp-server/#protected-resource-metadata) set, token validation instead runs through a generated AI MCP OAuth2 configuration, which adds OAuth 2.1 resource-server checks (token audience validation, protected resource metadata serving) on top of this AI Auth Strategy.

## Manage AI Auth Strategies

AI Auth Strategies can be created and managed through:

* {{site.konnect_short_name}} UI
* {{site.ai_gateway}} API: `/v1/ai-gateways/{aiGatewayId}/auth-strategies`
* [kongctl](/kongctl/)

For configuration examples and step-by-step setup instructions, see [Set up an AI Auth Strategy](#set-up-an-ai-auth-strategy).

## Default termination behavior

{% include /ai-gateway/auth-strategy-default-termination.md %}

## Authentication types

{{site.ai_gateway}} supports two auth strategy types. Choose based on how your AI Consumers authenticate:

{% table %}
columns:
  - title: Type
    key: type
  - title: When to use
    key: when
  - title: AI Consumer credential
    key: credential
rows:
  - type: "`key-auth`"
    when: "Your AI Consumers are internal tools, scripts, or teams that you control. You want to issue and rotate static API keys without involving an external identity provider."
    credential: "API key in a request header, query parameter, or request body"
  - type: "`openid-connect`"
    when: "Your AI Consumers already authenticate through an enterprise IdP (Okta, Azure AD, Google, or similar). You want to accept the tokens they already have rather than issuing separate keys."
    credential: "JWT bearer token or OAuth 2.0 grant from an external IdP"
{% endtable %}

An AI Model can use both at once, since each caller population often needs a different credential. For example, attach `key-auth` for internal automation that you issue static keys to, and `openid-connect` for user-facing applications that already authenticate through your enterprise IdP. 
A request from either population is authenticated if it satisfies either strategy. 

AI Agents and AI MCP Servers currently accept only one AI Auth Strategy reference each.

### API key authentication

The `key-auth` auth strategy validates an API key that the AI Consumer passes on every request. The gateway looks for the key in a configurable header or query parameter, checks it against the AI Consumer's registered key, and either authenticates the request or falls through to the [default termination behavior](#default-termination-behavior).

By default, {{site.ai_gateway}} accepts the key in an `apikey` header or `apikey` query parameter. Override the key name with `config.key_names`. For example, set `config.key_names: ["X-API-Key"]` to enforce a standard header name across your APIs.

{% table %}
columns:
  - title: Option
    key: option
  - title: Default
    key: default
  - title: Description
    key: description
rows:
  - option: "`key_in_header`"
    default: "`true`"
    description: "Accept the key in a request header."
  - option: "`key_in_query`"
    default: "`true`"
    description: "Accept the key as a query parameter."
  - option: "`key_in_body`"
    default: "`false`"
    description: "Accept the key in the request body. Supports `application/json`, `application/x-www-form-urlencoded`, and `multipart/form-data`."
  - option: "`hide_credentials`"
    default: "`true`"
    description: "Strip the key from the request before forwarding upstream."
{% endtable %}

### OIDC token authentication

The [`openid-connect` auth strategy](/ai-gateway/openid-connect/) validates a JWT or OAuth 2.0 token that the AI Consumer obtains from an external IdP. The gateway verifies the token against the IdP's published keys, maps the token to an AI Consumer, and either authenticates the request or falls through to the [default termination behavior](#default-termination-behavior).

Set `config.issuer` to the IdP's discovery URL (for example, `https://dev-123456.okta.com`). {{site.ai_gateway}} uses the OIDC discovery endpoint to fetch signing keys automatically.

The default `config.auth_methods` are `bearer` and `client_credentials`. If your AI Consumers use a different grant flow, add it to the list. For a full list of supported values, see the [Schema](#schema) section.

To map the token to an existing AI Consumer, set `config.consumer_claims` to an array of path segments locating the claim in the token that carries the AI Consumer identifier (for example, `[["user", "info", "id"]]` to map to a nested `user.info.id` claim). By default, a valid token that doesn't match any AI Consumer falls through to the [default termination behavior](#default-termination-behavior). Set `config.consumer_optional: true` to let that request proceed instead without an AI Consumer identity attached.

`config.cache_tokens_salt` is required for `openid-connect` AI Auth Strategies. It's a string used to generate the cache key for token endpoint request caching; set it to any unique value for this provider instance.

{:.warning}
> All AI Models in the same {{site.ai_gateway}} that use OIDC authentication must reference the same `openid-connect` AI Auth Strategy. Using different OIDC providers across models in the same {{site.ai_gateway}} is not supported.

## Identity mapping

An AI Auth Strategy can map a verified credential to an identity in two ways, and you can use either or both together.

### AI Consumer mapping

AI Consumer mapping maps a credential to an [AI Consumer](/ai-gateway/entities/ai-consumer/), a {{site.ai_gateway}}-local identity.
For `key-auth`, this mapping is intrinsic: the matched API key already belongs to a specific AI Consumer, created through the credentials endpoint.
For `openid-connect`, set `config.consumer_by`/`config.consumer_claims` to map a token claim to an AI Consumer instead.
By mapping to an AI Consumer, you can also use [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) membership, `access.acls`, attached [AI Policies](/ai-gateway/entities/ai-policy/), and per-consumer usage attribution.

### Principal mapping

{{site.identity}} Principal mapping (`config.principals`) instead looks the credential up against a [Kong Identity Principal](/identity/principals/), an identity shared across {{site.base_gateway}}, {{site.event_gateway_short}}, and {{site.dev_portal}}.
A Principal carries metadata you can use in conditional plugin execution, and scales past AI Consumer limits since Principals load on demand rather than living in data plane memory.
Both auth strategy types support `config.principals`.

You can configure both AI Consumer and Principal on the same `openid-connect` auth strategy.
`config.principals.match_consumer` (enabled by default when Principals are enabled) loads the AI Consumer linked to the matched Principal, overriding whatever `config.consumer_by` would otherwise have resolved.
This lets you manage identity centrally in {{site.identity}}, by linking a Principal to an AI Consumer through a `control_plane_consumer` identity, while still getting {{site.ai_gateway}}-native AI Consumer features (AI Policies, `access.acls`, AI Consumer Groups) for that same caller.

## Assigning an AI Auth Strategy

An AI Auth Strategy takes effect only when assigned to an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) (`conversion-listener`, `listener`, or `passthrough-listener` mode). Reference the provider by `name` or `id` in the entity's `access.auth_strategies` array:

```yaml
access:
  auth_strategies:
    - my-key-auth-provider
  acls:
    allow:
      - allowed-ai-consumer-group
```

{:.info}
> **Assignment rules**
> * Each AI Model supports one `key-auth` auth strategy and one `openid-connect` auth strategy. You can assign both types to the same AI Model; a request is authenticated if it satisfies either strategy.
> * Each AI Agent currently supports up to one AI Auth Strategy reference.
> * Each AI MCP Server (`conversion-listener`, `listener`, or `passthrough-listener` mode) currently supports up to one AI Auth Strategy reference. `upstream-server` AI MCP Servers authenticate to their upstream separately, through `config.server.tools_list_auth`; `conversion-only` AI MCP Servers have no `access` field.
> * AI Auth Strategies are the only supported way to authenticate inbound AI Consumer traffic to an AI Model, AI Agent, or AI MCP Server, and let each entity use different authentication independently. This is separate from outbound authentication to the upstream LLM, agent, or MCP server, which is configured on the AI Model Provider or the entity's own `config.upstream.auth`.

If you plan to rename the AI Auth Strategy later, reference it by `id` rather than name. The ID is stable across renames.

## Set up an AI Auth Strategy

### API key authentication

The following example creates a `key-auth` AI Auth Strategy that accepts AI Consumer API keys in the `X-API-Key` header:

{% entity_example %}
type: auth-strategy
data:
  display_name: API Key Auth
  name: api-key-auth
  type: key-auth
  config:
    key_names:
      - X-API-Key
    key_in_header: true
    key_in_query: false
    hide_credentials: true
{% endentity_example %}

### OIDC bearer token authentication

The following example creates an `openid-connect` AI Auth Strategy that accepts bearer tokens issued by Okta:

{% entity_example %}
type: auth-strategy
data:
  display_name: Okta AI SE
  name: okta-ai-se
  type: openid-connect
  config:
    issuer: https://dev-123456.okta.com
    client_id:
      - my-client-id
    client_secret:
      - my-client-secret
    auth_methods:
      - bearer
    scopes:
      - openid
    cache_tokens_salt: okta-ai-se-cache-salt
{% endentity_example %}

## Schema

{% entity_schema %}
