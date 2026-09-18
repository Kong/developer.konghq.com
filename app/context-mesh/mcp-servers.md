---
title: "{{site.context_mesh}} MCP servers"
content_type: reference
layout: reference

description: "Reference for {{site.context_mesh}} MCP servers, including how REST APIs are exposed as Code Mode MCP servers and how those servers are deployed and configured."

products:
    - context-mesh
    - konnect

works_on:
    - konnect

breadcrumbs:
  - /context-mesh/

tags:
  - mcp
  - ai

search_aliases:
  - Code Mode MCP
  - MCP server

---

{{site.context_mesh}} lets you turn enterprise assets (such as MCP servers and APIs) into context that AI agents can call. It works by composing those assets into a single deployable Code Mode MCP server, also called a Context Interface.

## Sources

Sources are the individual assets you add to {{site.context_mesh}} to compose create a deployable  MCP server. There are two types of sources:

- **API:** Import it from the {{site.konnect}} [**Catalog**](/catalog/), or upload a spec file. 
- **MCP server endpoint:** Add the URL to the configuration.

You have to add sources to {{site.context_mesh}} before creating an MCP server. Once you've added sources, you can combine and reuse them to create different contexts. You can configure each source with the following fields:

{% feature_table %}
item_title: Field
columns:
  - title: Description
    key: description
  - title: Required
    key: required
features:
  - title: "Display name"
    description: Source name in the UI.
    required: true
  - title: "Name"
    description: |
      Machine name. Must be unique within the org. Auto-populated from the **Display name.
    required: true
  - title: "Description"
    description: Auto-populated from Catalog description or API spec where possible.
    required: false
  - title: "Labels"
    description: Key-value tags for filtering/searching across {{site.konnect}}.
    required: false
    required: true
  - title: "Base URL"
    description: |
      Overrides whatever base URL is (or isn't) defined in the OpenAPI spec.
    required: false
  - title: "Custom headers"
    description: |
      Extra HTTP headers injected onto every request that Context Mesh formards to the source's backing service, for auth and identification.
    required: false

{% endfeature_table %}

Once you've added and configured the {{site.context_mesh}}, you can create an MCP server.

## MCP servers

{{site.context_mesh}} MCP servers are the composion layer you create to bundle different sources together and deploy deploy them as a single Code Mode MCP server.

## Auth

## Deployments