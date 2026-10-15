---
title: "{{site.context_mesh}} sources"
content_type: reference
layout: reference
beta: true

permalink: /context-mesh/sources/
description: "Reference for {{site.context_mesh}} sources, the APIs and remote MCP servers you add to compose Code Mode MCP servers, including their configuration fields, custom headers, and how to add them."

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
  - Context source
  - API source
  - Remote MCP server source

related_resources:
  - text: "{{site.context_mesh}}"
    url: /context-mesh/
  - text: "{{site.context_mesh}} MCP servers"
    url: /context-mesh/mcp-servers/
  - text: "Deploy an MCP server with {{site.context_mesh}} and {{site.operator_product_name}}"
    url: /context-mesh/get-started/
  - text: "{{site.context_mesh}} API reference"
    url: /api/konnect/context-interfaces/v1/
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "Stages of software availability"
    url: /stages-of-software-availability/

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

Sources are the individual assets you add to {{site.context_mesh}} before you create an MCP server. They are the APIs and remote MCP servers that agents end up calling. After you add a source, you can combine them into a single [{{site.context_mesh}} MCP server](/context-mesh/mcp-servers/).

## Source types

There are two types of sources you can add to {{site.context_mesh}}:

- **API sources:** Import an API from the {{site.konnect}} [**Catalog**](/catalog/), or upload an OpenAPI spec file.
- **MCP server sources:** Add the URL of an existing remote MCP server.

Add sources to {{site.context_mesh}} before creating an MCP server. After adding sources, you can combine and reuse them to create different contexts. You can configure each source with the following fields:

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
      Machine name. Must be unique within the org. Auto-populated from the **Display name**.
    required: true
  - title: "Description"
    description: Auto-populated from the {{site.konnect}} Catalog description or API spec where possible.
    required: false
  - title: "Labels"
    description: Key-value tags for filtering/searching across {{site.konnect}}. In the API, send `{}` if you don't want to add any labels.
    required: Only with the API
  - title: "Base URL"
    description: |
      Overrides whatever base URL is (or isn't) defined in the OpenAPI spec.
    required: false
  - title: "Custom headers"
    description: |
      Extra HTTP headers injected onto every request that {{site.context_mesh}} forwards to the source's backing service, for example to identify the caller. Stored unencrypted, so don't use them for secrets or sensitive information.
    required: false

{% endfeature_table %}

You can update these fields at any time to change a {{site.context_mesh}} source's configuration.

By default, a {{site.context_mesh}} MCP server inherits everything a source can do. To restrict specific paths, methods, or tools without changing the source, see [Blocked capabilities](/context-mesh/mcp-servers/#blocked-capabilities).

## Custom headers

When an agent calls a tool through a {{site.context_mesh}} MCP server, that call turns into a network request: an HTTP call to an API, or a proxied call to a remote MCP server. Custom headers let you add the same HTTP headers to every one of those requests, for example to identify the caller or route the request on the backing service. They work as follows:

1. You configure the custom headers once on the {{site.context_mesh}} source.
1. {{site.context_mesh}} attaches the custom headers to every request it sends to that source's backing service. The agent never sees them.

{:.warning}
> {{site.context_mesh}} stores custom headers unencrypted. Don't use them for secrets or sensitive information, such as API keys, bearer tokens, or passwords.

Custom headers on {{site.context_mesh}} sources have these properties:

* You set them per source, not per {{site.context_mesh}} MCP server. If three {{site.context_mesh}} MCP servers use the same source, all three send the same headers. There's no {{site.context_mesh}} MCP server override for this.
* They're plain-text key-value pairs. The schema is: `headers: { additionalProperties: string }`.
* They work the same way for both source types. API sources and MCP server sources both support them, with the same shape.
* They're optional.

## Add a source

Repeat these steps for each source you want an MCP server to expose. You can create a source from an API spec file or from a remote MCP server. To use an API from the {{site.konnect_catalog}} instead, see [Import an API from the Catalog](#import-an-api-from-the-catalog).

{:.info}
> The [{{site.context_mesh}} API](/api/konnect/context-interfaces/v1/) calls sources `context-sources`, so the endpoints use `/v1/context-sources`.

The following examples use [Kong Air](https://github.com/KongAirlines/routes/blob/main/openapi.yaml) as an example. Replace the fields with your own values.

### Upload an API spec

{% navtabs "upload-api-spec" %}
{% navtab "API" %}

The `spec` field takes the contents of your OpenAPI spec, in JSON or YAML, as a single string. Build the request body from your spec file with `jq`, replacing `openapi.yaml` with the path to your spec:

```sh
jq -n --rawfile spec openapi.yaml '{
  "name": "flights-api",
  "display_name": "Flights API",
  "description": "Flight search and booking operations",
  "labels": {},
  "type": "api",
  "source": {
    "type": "raw",
    "config": {
      "spec": $spec,
      "base_url": "https://api.example.com",
      "headers": {"X-Client-Name": "travel-assistant"}
    }
  }
}' > source.json
```

Send a `POST` request to the [Create a Context Source](/api/konnect/context-interfaces/v1/#/operations/create-context-source) endpoint with the request body:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-sources
status_code: 201
method: POST
body_cmd: $(cat source.json)
{% endkonnect_api_request %}
<!--vale on-->

`base_url` and `headers` are optional. If you omit `base_url`, {{site.context_mesh}} uses the server URL defined in the spec.

{% endnavtab %}
{% navtab "UI" %}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.context_mesh}}**.
1. In the {{site.context_mesh}} sidebar, click **Sources**.
1. Click **New source**.
1. Select **API**.
1. Click the **Upload new** tab.
1. Click **Select File**, then select your local OpenAPI spec file.
1. In the **Display name** field, enter `Flights API`. The **Name** field autofills from it.
1. Optional: In the **Description** field, enter a description for the source.
1. Optional: In the **Base URL** field, enter `https://api.example.com`. If you leave it empty, {{site.context_mesh}} uses the server URL defined in the spec.
1. Click **Add Source**.

{% endnavtab %}
{% endnavtabs %}

### Add a remote MCP server

{% navtabs "add-mcp-server" %}
{% navtab "API" %}

Send a `POST` request to the [Create a Context Source](/api/konnect/context-interfaces/v1/#/operations/create-context-source) endpoint with the URL of the remote MCP server:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-sources
status_code: 201
method: POST
body:
  display_name: Flights MCP
  name: flights-mcp
  description: Flight status tools from the flights team MCP server
  labels: {}
  type: mcp_server
  source:
    type: remote_mcp_server
    config:
      url: https://mcp.example.com/mcp
      headers:
        X-Client-Name: travel-assistant
{% endkonnect_api_request %}
<!--vale on-->

The `url` must include the protocol (`http` or `https`) and can't contain query parameters or fragments. The `headers` field is required for MCP server sources. If you don't need custom headers, set it to `{}`.

{% endnavtab %}
{% navtab "UI" %}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.context_mesh}}**.
1. In the {{site.context_mesh}} sidebar, click **Sources**.
1. Click **New source**.
1. Select **MCP Server**.
1. In the **Display name** field, enter the name of the remote MCP server. The **Name** field autofills from it.
1. Optional: In the **Description** field, enter a description for the source.
1. In **Configuration**, under **Upstream URL**, enter the remote MCP server URL. The URL must include `http` or `https` and can't contain query parameters or fragments.
1. Click **Add MCP server**.

{% endnavtab %}
{% endnavtabs %}

### Import an API from the Catalog

{% navtabs "import-source" %}
{% navtab "API" %}

To import an API from the {{site.konnect_catalog}}, you need the API ID and the ID of the API version to use. The {{site.konnect_short_name}} UI doesn't display the version ID, so get both IDs from the API:

1. Send a `GET` request to the [List APIs](/api/konnect/api-builder/v3/#/operations/list-apis) endpoint to list the APIs in your {{site.konnect_catalog}}. Find your API in the response and copy its `id`:

   ```sh
   curl -X GET "https://us.api.konghq.com/v3/apis" \
        --no-progress-meter --fail-with-body \
        -H "Authorization: Bearer $KONNECT_TOKEN" \
        | jq '.data[] | {id, name}'
   ```

   Export the ID as an environment variable, replacing `YOUR_API_ID` with the `id` you copied:

   ```sh
   export API_ID='YOUR_API_ID'
   ```

1. Send a `GET` request to the [List API Versions](/api/konnect/api-builder/v3/#/operations/list-api-versions) endpoint to get the versions of that API. The command saves the ID of the first version returned as the `API_VERSION_ID` environment variable:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v3/apis/$API_ID/versions
   status_code: 200
   method: GET
   indent: 3
   capture:
     - variable: API_VERSION_ID
       jq: ".data[0].id"
   {% endkonnect_api_request %}
   <!--vale on-->

1. Send a `POST` request to the [Create a Context Source](/api/konnect/context-interfaces/v1/#/operations/create-context-source) endpoint with the IDs:

   <!--vale off-->
   {% konnect_api_request %}
   url: /v1/context-sources
   status_code: 201
   method: POST
   indent: 3
   body:
     display_name: Flights API
     name: flights-api
     description: Flight search and booking operations
     labels: {}
     type: api
     source:
       type: api_catalog
       config:
         api_id: $API_ID
         api_version_id: $API_VERSION_ID
         base_url: https://api.example.com
         headers:
           X-Client-Name: travel-assistant
   {% endkonnect_api_request %}
   <!--vale on-->

{% endnavtab %}
{% navtab "UI" %}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.context_mesh}}**.
1. In the {{site.context_mesh}} sidebar, click **Sources**.
1. Click **New source**.
1. In the **Import from Catalog** tab, select the Catalog APIs to include as sources.

{% endnavtab %}
{% endnavtabs %}

