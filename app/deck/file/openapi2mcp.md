---
title: deck file openapi2mcp
description: Convert an OpenAPI specification to a Gateway Service with an MCP Route, an AI MCP Proxy plugin, and MCP tools.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/file/

tags:
  - openapi
  - declarative-config
  - mcp
---

The `openapi2mcp` command converts OpenAPI files to Kong's decK format with MCP (Model Context Protocol) configuration.

## MCP tool generation

This command generates a {{site.base_gateway}} Service with an MCP route that includes the 
[AI MCP Proxy plugin](/plugins/ai-mcp-proxy/) configured with tools derived from the OpenAPI specification operations.

Each OpenAPI spec component is mapped to an MCP tool definition:

{% table %}
columns:
  - title: Component
    key: component
  - title: MCP tool mapping
    key: map
rows:
  - component: `operationId`
    map: "Tool name (kebab-case normalized)"
  - component: "Summary/description"
    mapping: "Tool description"
  - component: Parameters
    map: Tool parameters array
  - component: `requestBody`
    map: "Tool `request_body`"
{% endtable %}

## Security/ACL generation

When an OAuth2 security scheme includes the `x-kong-mcp-acl` extension, ACL entries
are automatically generated for each tool based on the operation's security scopes.
The plugin config will include `acl_attribute_type`, `access_token_claim_field`, and per-tool `acl.allow` arrays. 

* Use `x-kong-mcp-default-acl` at the document level to set a default ACL for the plugin. 
* Use `--ignore-security-errors` to skip unsupported security configurations instead of failing.

## Supported extensions

Supported `x-kong` extensions:
<!--vale off-->
{% table %}
columns:
  - title: Annotation
    key: annotation
  - title: Description
    key: description
rows:
  - annotation: "`x-kong-name`"
    description: Custom entity naming.
  - annotation: "`x-kong-tags`"
    description: Tags for all entities.
  - annotation: "`x-kong-service-defaults`"
    description: Service entity defaults.
  - annotation: "`x-kong-route-defaults`"
    description: Route entity defaults.
  - annotation: "`x-kong-upstream-defaults`"
    description: Upstream entity defaults.
  - annotation: "`x-kong-plugin-*`"
    description: Additional plugins.
{% endtable %}
<!--vale on-->

Supported MCP-specific extensions:
<!--vale off-->
{% table %}
columns:
  - title: Annotation
    key: annotation
  - title: Description
    key: description
rows:
  - annotation: "`x-kong-mcp-tool-name`"
    description: Override generated tool name.
  - annotation: "`x-kong-mcp-tool-description`"
    description: Override tool description.
  - annotation: "`x-kong-mcp-exclude`"
    description: Exclude operation from tool generation (boolean).
  - annotation: "`x-kong-mcp-proxy`"
    description: Override AI MCP Proxy plugin config at document level.
{% endtable %}
<!--vale on-->

Supported security extensions:
<!--vale off-->
{% table %}
columns:
  - title: Annotation
    key: annotation
  - title: Description
    key: description
rows:
  - annotation: "`x-kong-mcp-acl`"
    description: "ACL config on OAuth2 security scheme (`acl_attribute_type`, `access_token_claim_field`)."
  - annotation: "`x-kong-mcp-default-acl`"
    description: "Default ACL array at document level (`scope`, `allow`)."
{% endtable %}
<!--vale on-->

## Convert an OpenAPI file to a Kong state file with MCP config

Converting an OpenAPI file to a Kong declarative configuration with MCP configuration can be done in a single command:

```bash
deck file openapi2mcp --spec oas.yaml --output-file kongmcp.yaml
```

## Command usage

{% include_cached deck/help/file/openapi2mcp.md %}
