---
title: 'AI MCP OAuth2'
name: 'AI MCP OAuth2'

content_type: plugin
tier: ai_gateway_enterprise
publisher: kong-inc
description: 'Secure MCP server access with OAuth2 authentication'

tech_preview: true
products:
    - gateway
    - ai-gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.12'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

tags:
  - ai
  - mcp

search_aliases:
  - ai-mcp-oauth2
  - OAuth2
  - MCP


icon: ai-mcp-oauth2.png

categories:
   - ai
related_resources:
  - text: OAuth 2.0 specification for MCP
    url: https://modelcontextprotocol.io/specification/draft/basic/authorization
  - text: MCP Traffic Gateway
    url: /mcp/
---

The AI MCP OAuth2 plugin secures Model Context Protocol (MCP) traffic on {{site.ai_gateway}} using [OAuth 2.0 specification for MCP servers](https://modelcontextprotocol.io/specification/draft/basic/authorization). It ensures only authorized MCP clients can access protected MCP servers, and acts as a crucial security layer for MCP servers.


{:.warning}
> **Breaking change**
>
> {% new_in 3.13 %}The MCP OAuth2 plugin now treats all incoming traffic as MCP requests to address a potential authentication bypass vulnerability.
>
> Do not use this plugin with the [AI MCP Proxy](/plugins/ai-mcp-proxy) plugin in [`conversion-listener` mode](/plugins/ai-mcp-proxy/#configuration-modes) on the same route. Non-MCP requests will fail.
>
> Use MCP OAuth2 with MCP Proxy in `listener` or `passthrough-listener` modes. For REST API exposure, configure MCP Proxy in `conversion-only` mode on a separate route.

## Purpose and core functionality

The plugin provides OAuth 2.0 authentication for MCP traffic, allowing MCP clients to safely request access. It validates that access tokens are issued specifically for the target MCP server, ensuring only authorized requests are accepted. To reduce the risk of token theft or confused deputy attacks, the plugin does not pass access tokens to upstream services.

The plugin performs three core functions:

* Validates incoming MCP requests by verifying access tokens from an external Authorization Server.
* Extracts claims from validated tokens and forwards them to upstream MCP services via headers.
* Ensures compliance with MCP authorization requirements based on OAuth 2.1.

## Authorization flow

The plugin follows the following authorization flow:

* {{site.ai_gateway}} acts as the **Resource Server**, enforcing access control.
* The MCP clients send requests with a valid `Authorization: Bearer <access-token>` header.
* The plugin validates tokens, checks the intended audience, and blocks invalid or expired tokens with a `401 Unauthorized`.
* Access tokens are **never passed to upstream services**, protecting against token theft or confused deputy attacks.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as MCP client
    participant K as AI MCP OAuth2 plugin
    participant AS as Authorization server
    participant U as Upstream MCP server

    C->>K: Discover protected resource metadata
    activate K
    K-->>C: Protected resource metadata (includes auth server address)
    deactivate K

    C->>AS: Request access token
    activate AS
    AS-->>C: Access token
    deactivate AS

    C->>K: MCP auth request
    activate K
    K->>AS: Introspect token
    activate AS
    AS-->>K: Valid / invalid
    deactivate AS

    alt If token valid
        K->>U: Forward request with claims as headers
        activate U
        U-->>K: MCP server response
        deactivate U
        K-->>C: MCP response
    else If token invalid
        K-->>C: 401 Unauthorized
    end
    deactivate K

{% endmermaid %}
<!-- vale on -->

## Plugin execution

The AI MCP OAuth2 plugin is designed to secure MCP traffic as early as possible in the request lifecycle to prevent unauthorized access before any AI-specific processing occurs.

{:.warning}
> **Note:** Like, the AI MCP Proxy plugin, the AI MCP OAuth2 plugin is not invoked as part of an LLM request flow.
>
> Instead, it is registered and executed as a regular plugin, allowing it to capture MCP traffic independently of LLM request flow.
> The AI MCP OAuth2 plugin can be used on its own for upstream MCP proxying or in combination with the AI MCP Proxy plugin when request/response conversion is needed.
