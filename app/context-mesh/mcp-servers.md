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
  - q: What is a Code Mode MCP server?
    a: |
      [Code Mode](https://blog.cloudflare.com/code-mode/) is a configuration that exposes an API as a single SDK-like interface instead of one tool per operation.
      The agent writes short code snippets against that interface rather than choosing between many similar tools, and only the final result returns to the context window.
      This lets an agent work with a large API surface without flooding the model's context. {{site.context_mesh}} generates all of its MCP servers in Code Mode.
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
  - q: Can I add auth to a {{site.context_mesh}} MCP server?
    a: |
      Not on the MCP server itself. You configure authentication on the source using custom headers, and {{site.context_mesh}} attaches those headers to every request it sends to that source's backing service.
      Because headers belong to the source, every MCP server built from that source sends the same headers. There is no per MCP server override.
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

* **API sources:** each operation in the OpenAPI spec (a path and a method, for example `/flight` and `GET`) becomes a capabiliy. {{site.context_mesh}} automatically turns API operations into MCP tools. It does this by translatinf each API opeartion into Python code that creates an MCP tool that your agents can call. Fore example, an API source's `GET /flights` operation becomes a `listFlights` tool.
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

## Blocked capabilities

By default, {{site.context_mesh}} inherits everything a source can do. For example, if an API source contains 20 operations, the {{site.context_mesh}} MCP server that uses it gives the agent access to the 20 operations. The same applies to all the tools a remote MCP server source exposes.

{{site.context_mesh}} MCP servers lets you restrict specific paths, methods, and tools, without changing the source itself, using **blocked capabilities**. This feature blocks source items on a specific {{site.context_mesh}} MCP server. This tells the {{site.context_mesh}} MCP server to let agents access the designated items. You configure this at the {{site.context_mesh}} MCP server level, on each source listed in its configuration.

What you can block depends on the type of source the {{site.context_mesh}} MCP server uses:

{% table %}
columns:
  - title: Source type
    key: source
  - title: What you can block
    key: item
  - title: Examples
    key: examples
rows:
  - source: "**API sources**"
    item: |
      * Paths
      * Methods
    examples: |
      * `/flights`
      * `PUT`
  - source: "**MCP server sources**"
    item: |
      * Tools
      * Resources
      * Prompts
    examples: |
      * `listFlights`
      * `flight-schedule.json`
      * `summarize-booking`

{% endtable %}

## Auth

{{site.context_mesh}} sources can contain an authetication layer with custom headers. When an agent calls a tool though a {{site.context_mesh}} MCP server, that call turns into a network request: an HTTP call to an API, or a proxied call to a remote MCP server. Custom headers are a set of key-value pairs that work as follows:

1. You configure the custom headers once on the {{site.context_mesh}} source.
1. {{site.context_mesh}} attach the custom headers to every request, without the agent ever knowing they exist.

Custom headers on {{site.context_mesh}} sources have these properties:

* You set them per Source, not per {{site.context_mesh}} MCP server. If three {{site.context_mesh}} MCP servers use the same source, all three send the same headers. Tthere's no {{site.context_mesh}} MCP server override for this.
* They're plain key-value text pairs. The schema is: `headers: { additionalProperties: string }`.
* They apply identically to both source types: API sources and MCP server sources both support them, with the same shape.
* They're optional.

## Deployments


## Set up a {{site.context_mesh}} MCP server

Setting up a {{site.context_mesh}} MCP server is a multi-step process. You create the sources first, then the MCP server, then map each source to it. Deploying to a control plane is the final step.

{:.info}
> The API uses `/v1/context-interfaces` for {{site.context_mesh}} MCP servers. Wherever the endpoints refer to a context interface, that is a {{site.context_mesh}} MCP server.

### Create a source

Repeat this step for each source you want the MCP server to expose.

{% navtabs "create-source" %}
{% navtab "API" %}

Send a `POST` request to the `/v1/context-sources` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-sources
status_code: 201
method: POST
body:
  display_name: Flights API
  name: flights-api
  description: Flight search and booking operations
  base_url: https://api.example.com
  headers:
    Authorization: Bearer $API_TOKEN
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "UI" %}

{% endnavtab %}
{% endnavtabs %}

### Create the MCP server

{% navtabs "create-mcp-server" %}
{% navtab "API" %}

Send a `POST` request to the `/v1/context-interfaces` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces
status_code: 201
method: POST
body:
  display_name: Travel Assistant
  name: travel-assistant
  description: Flight and booking context for travel agents
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "UI" %}

{% endnavtab %}
{% endnavtabs %}

### Map the sources to the MCP server

{% navtabs "map-sources" %}
{% navtab "API" %}

Send a `POST` request to the `/v1/context-interfaces/{interfaceId}/context-source-mappings` endpoint for each source:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$INTERFACE_ID/context-source-mappings
status_code: 201
method: POST
body:
  context_source_id: $SOURCE_ID
{% endkonnect_api_request %}
<!--vale on-->

{:.info}
> To block capabilities on a mapping, send a `POST` request to `/v1/context-interfaces/{interfaceId}/context-source-mappings/{mappingId}/capability-controls`.
> Use `PATCH` on the same endpoint to change them later. Omitted deny keys keep their existing value, an empty array clears a capability, and a non-empty array replaces it.

{% endnavtab %}
{% navtab "UI" %}

{% endnavtab %}
{% endnavtabs %}

### Deploy the MCP server

Deploy the MCP server by mapping it to a control plane.

{% navtabs "deploy-mcp-server" %}
{% navtab "API" %}

Send a `POST` request to the `/v1/context-interfaces/{interfaceId}/control-plane-mappings` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$INTERFACE_ID/control-plane-mappings
status_code: 201
method: POST
body:
  control_plane_id: $CONTROL_PLANE_ID
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "UI" %}

{% endnavtab %}
{% endnavtabs %}

### Check the deployment status

{% navtabs "check-status" %}
{% navtab "API" %}

Send a `GET` request to the `/v1/context-interfaces/{interfaceId}/status` endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$INTERFACE_ID/status
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

To review the Python code {{site.context_mesh}} generates for the MCP server, send a `GET` request to `/v1/context-interfaces/{interfaceId}/code`.

{% endnavtab %}
{% navtab "UI" %}

{% endnavtab %}
{% endnavtabs %}
