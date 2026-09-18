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

faqs:
  - q: Does a source stay in sync with the {{site.konnect_catalog}}?
    a: |
      No. When you add a source from the {{site.konnect_short_name}} {{site.konnect_catalog}}, {{site.context_mesh}} creates a forked copy of the item.
      There is no sync between {{site.context_mesh}} and the {{site.konnect_catalog}}.
  - q: Can I change a source's type or definition after I create it?
    a: |
      No. You can't change a source's type, for example changing an API into an MCP server, and you can't update the spec or the MCP server endpoint.
      To update a source, create a new source and delete the outdated one.
  - q: Can I add new tools to an MCP server source from {{site.context_mesh}}?
    a: |
      No. {{site.context_mesh}} inherits the tools that an MCP server source already exposes.
      You can't define additional tools on the source from {{site.context_mesh}}, only proxy them.  
---

{{site.context_mesh}} lets you turn enterprise assets (such as MCP servers and APIs) into context that AI agents can call. It works by composing those assets into a single deployable Code Mode MCP server.

## Sources

Sources are the individual assets you add to {{site.context_mesh}} to compose create a deployable  MCP server. There are two types of sources:

- **API sources:** Import it from the {{site.konnect}} [**Catalog**](/catalog/), or upload a spec file. 
- **MCP server sources:** Add the URL to the configuration.

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
    description: Auto-populated from the {{site.konnect}} Catalog description or API spec where possible.
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

You can update these fields at any time to change a {{site.context_mesh}} source's configuration.

## {{site.context_mesh}} MCP servers

{{site.context_mesh}} MCP servers are the composion layer you create to bundle different sources together and deploy deploy them as a single Code Mode MCP server. This becomes the source of truth for your agents after you deploy them on a {{site.konnect}} Control Plane.

Each {{site.context_mesh}} MCP server inherits the capabilities listed in each one of its sources as follows:

* **API sources:** each operation in the OpenAPI spec (a path and a method, for example `/flight` and `GET`) becomes a capabiliy. {{site.context_mesh}} automatically turns API operations into MCP tools.
* **MCP server sources:** {{site.context_mesh}} inherits whatever tools the remote MCP server already exposes. {{site.context_mesh}} doesn't define the tools, it only proxies them.

When you create a {{site.context_mesh}} MCP server, you configure it with the following parameters:

{% feature_table %}
item_title: Parameter
columns:
  - title: Description
    key: description
  - title: Required
    key: required
    key: edit
features:
  - title: "Sources"
    description: {{site.context_mesh}} sources you've previously added.
    required: true
  - title: "Display name"
    description: MCP server's name in the UI.
    required: true
  - title: "Name"
    description: |
      Machine name. Must be unique within the org. Auto-populated from the **Display name.
    required: true
  - title: "Description"
    description: The {{site.context_mesh}} MCP server description.
    required: false
  - title: "Labels"
    description: Key-value tags for filtering/searching across {{site.konnect}}.
    required: false
    required: true

{% endfeature_table %}

You can deploy the {{site.context_mesh}} MCP server at creation or later.

### Code Mode

## Blocked capabilities




## Auth

## Deployments