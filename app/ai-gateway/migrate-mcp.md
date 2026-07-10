---
title: "Migrate your MCP servers to {{site.ai_gateway}} 2.x"
content_type: reference
layout: reference

works_on:
 - konnect

products:
  - ai-gateway
breadcrumbs:
  - /ai-gateway/
tags:
  - ai

  
min_version:
  ai-gateway: '2.0'

description: This guide walks you through moving your MCP servers to the new {{site.ai_gateway}} AI MCP Server entities.
---

In {{site.ai_gateway}} version 1.x, an MCP server is an [AI MCP Proxy](/plugins/ai-mcp-proxy/) plugin attached to a Service and Route. The plugin runs in one of four modes and holds the tools, Access Control Lists (ACLs), and logging settings in its config.

In {{site.ai_gateway}} version 2.x, that plugin becomes a single [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity, with the following changes:
* The plugin `mode` setting becomes an MCP Server `type` setting. This part of the migration essentially consists in copying whatever value you set in `config.mode` to the `type` setting.
* ACLs, which were plugin fields in version 1.x, become a top-level fields on the AI MCP Server.

The following table maps each version 1.x plugin mode to its version 2.x MCP Server type:

{% table %}
columns:
  - title: "Version 1.x MCP proxy `config.mode`"
    key: mode
  - title: "Version 2.x AI MCP Server `type`"
    key: type
rows:
  - mode: "`passthrough-listener`"
    type: "`passthrough-listener`"
  - mode: "`conversion-listener`"
    type: "`conversion-listener`"
  - mode: "`conversion-only`"
    type: "`conversion-only`"
  - mode: "`listener`"
    type: "`listener`"
  - mode: "(no version 1.x equivalent)"
    type: "`upstream-server`"
{% endtable %}

## Converting configuration files

The following version 1.x example config:
* Converts a REST flights API into MCP tools
* Serves the tools on a Route, with `key-auth` in front and a default ACL:

```
# kong.yaml (AI Gateway v1, exported with deck gateway dump)
services:
- name: kongair-flights
  url: https://flights.internal.kongair.com
  routes:
  - name: kongair-flights-mcp
    paths:
    - /flights-mcp
  plugins:
  - name: key-auth
  - name: ai-mcp-proxy
    config:
      mode: conversion-listener
      logging:
        log_statistics: true
        log_audits: true
      default_acl:
        allow:
        - flight-operators
      tools:
      - name: search_flights
        description: Search available flights
        # ...OpenAPI-derived tool definition...
```

Converting the example to use the version 2.x model:
* Moves the upstream URL, route, tools, and logging settings onto a single AI MCP Server entity
* Copies the value from the plugin `mode` into the MCP Server `type` .
* Converts the `key-auth` plugin into a Policy and attaches it to the MCP Server.
* Renames `default_acl` to `default_tool_acls` and sets the ACL evaluation mode explicitly with `acl_attribute_type`.
* Renames the `config.logging` fields: `log_statistics` becomes `statistics`, and `log_audits` becomes `audits`.

```
# ai-gateway.yaml (AI Gateway v2 entity model)
policies:
- type: key-auth
  name: flights-key-auth
  display_name: Flights Key Auth
  config: {}

mcp-servers:
- type: conversion-listener
  name: kongair-flights
  display_name: Kong Air Flights
  enabled: true
  access:
    acl_attribute_type: consumer
    acls:
      allow: []
      deny: []
    default_tool_acls:
      allow:
      - flight-operators
      deny: []
  policies:
  - flights-key-auth
  config:
    url: https://flights.internal.kongair.com
    route:
      paths:
      - /flights-mcp
    logging:
      statistics: true
      audits: true
  tools:
  - name: search_flights
    description: Search available flights
    # ...OpenAPI-derived tool definition...
```

## What to check on AI MCP Servers

- Mode and type: confirm the `type` matches the original mode. The `conversion-only` and `conversion-listener` modes require Route information, so make sure the converted entity includes a `config.route`.
- Listener aggregation: if you used `conversion-only` plugins feeding a `listener` plugin via tags in version 1.x, confirm the converter preserved the tags so the version 2.x listener AI MCP Server still aggregates the right tools.
- ACL mode: version 2.x makes the ACL subject explicit. Use `acl_attribute_type: consumer` to evaluate against Consumers and Consumer Groups, or `acl_attribute_type: oauth_access_token` with `access_token_claim_field` to evaluate against a claim in an OAuth2 access token.
- Per-tool ACLs: a per-tool `acl` replaces the default for that tool and does not merge with `default_tool_acls`. Ensure every allowed subject is listed on the tool explicitly.
- Logging field names: the version 1.x `log_statistics`, `log_payloads`, and `log_audits` fields become `statistics`, `payloads`, and `audits` under `config.logging`.