---
title: "{{site.context_mesh}} MCP servers"
content_type: reference
layout: reference
beta: true

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

related_resources:
  - text: "{{site.context_mesh}}"
    url: /context-mesh/
  - text: "Deploy an MCP server with {{site.context_mesh}} and {{site.operator_product_name}}"
    url: /context-mesh/get-started/
  - text: "{{site.context_mesh}} API reference"
    url: /api/konnect/context-interfaces/v1/
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.operator_product_name}}"
    url: /operator/
  - text: "Stages of software availability"
    url: /stages-of-software-availability/

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
      Not on the MCP server itself. You can set custom headers on a source, and {{site.context_mesh}} attaches them to every request it sends to that source's backing service.
      However, {{site.context_mesh}} stores custom headers unencrypted, so you can't use them for credentials such as API keys, bearer tokens, or passwords.
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
      Machine name. Must be unique within the org. Auto-populated from the **Display name**.
    required: true
  - title: "Description"
    description: Auto-populated from the {{site.konnect}} Catalog description or API spec where possible.
    required: false
  - title: "Labels"
    description: Key-value tags for filtering/searching across {{site.konnect}}. In the API, send `{}` if you don't want to add any labels.
    required: true
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

## {{site.context_mesh}} MCP servers

{{site.context_mesh}} MCP servers are the composition layer you create to bundle different sources together and deploy them as a single Code Mode MCP server. This becomes the source of truth for your agents after you deploy them on a {{site.konnect}} Control Plane.

Each {{site.context_mesh}} MCP server inherits the capabilities listed in each one of its sources as follows:

* **API sources:** each operation in the OpenAPI spec (a path and a method, for example `/flight` and `GET`) becomes a capability. {{site.context_mesh}} automatically turns API operations into MCP tools. It does this by translating each API operation into Python code that creates an MCP tool that your agents can call. Fore example, an API source's `GET /flights` operation becomes a `listFlights` tool.
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
    description: Key-value tags for filtering/searching across {{site.konnect}}. In the API, send `{}` if you don't want to add any labels.
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

## Deployments

To run the {{site.context_mesh}} MCP server, you deploy it on a {{site.konnect}} Control Plane.
You can deploy a {{site.context_mesh}} MCP server in two modes:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: How it works
    key: description
rows:
  - mode: "**Basic**"
    description: |
      The default mode. {{site.konnect_short_name}} handles the deployment:
      1. It generates the server code from the sources.
      1. It runs the code in containers.
      1. It sets up the {{site.base_gateway}} [Routes](/gateway/entities/route/) and [Services](/gateway/entities/service/) needed to receive traffic.
  - mode: "**Advanced** ([Tech Preview](/stages-of-software-availability/#tech-preview))"
    description: |
      You control the deployment directly with [{{site.operator_product_name}}](/operator/) custom resources instead of using the {{site.konnect_short_name}} defaults.

{% endtable %}

{:.warning}
> Advanced mode is in [Tech Preview](/stages-of-software-availability/#tech-preview) and should not be used in a production environment.

You can deploy the same {{site.context_mesh}} MCP server to more than one control plane at once.

The MCP server reports a status so you can tell whether it's up and working:

{% table %}
columns:
  - title: Status
    key: status
  - title: Description
    key: description
rows:
  - status: "**Healthy**"
    description: The MCP server is running and serving traffic.
  - status: "**Deploying**"
    description: {{site.konnect_short_name}} is rolling out the MCP server for the first time.
  - status: "**Upgrading**"
    description: {{site.konnect_short_name}} is rolling out a new version over a running MCP server.
  - status: "**Unhealthy**"
    description: The MCP server is deployed but isn't serving traffic correctly.
  - status: "**Pending**"
    description: The MCP server is mapped to a control plane, but the rollout hasn't started.

{% endtable %}

You can see this status in the {{site.konnect_short_name}} UI. To check the deployment outside the UI, check the MCP server pod in your cluster instead. {{site.operator_product_name}} runs each {{site.context_mesh}} MCP server as a deployment with the `mcpserver-` prefix. To confirm the pod is running, replace `NAMESPACE` with your namespae and run the following command with kubectl:

```sh
kubectl get pods -n NAMESPACE | grep mcpserver
```

A healthy MCP server shows `1/1` ready with the `Running` status. For example:

```text
mcpserver-test-45675cb3-764b4d6d6c-q2gnp   1/1     Running   0   57m
```

If the pod stays in `Pending` or `CrashLoopBackOff`, check its logs with `kubectl logs -n NAMESPACE POD_NAME`.

For the full deployment flow, see [Deploy an MCP server with {{site.context_mesh}} and {{site.operator_product_name}}](/context-mesh/get-started/).

## Set up a {{site.context_mesh}} MCP server

Setting up a {{site.context_mesh}} MCP server is a multi-step process. You create the sources first, then the MCP server, then map each source to it. Deploying to a control plane is the final step.

{:.info}
> The [{{site.context_mesh}} API](/api/konnect/context-interfaces/v1/) uses `/v1/context-interfaces` for {{site.context_mesh}} MCP servers. Wherever the endpoints refer to a context interface, that is a {{site.context_mesh}} MCP server.

### Create a source

Repeat this step for each source you want the MCP server to expose. You can create a source from an API spec file or from a remote MCP server. To use an API from the {{site.konnect_catalog}} instead, see [Import a source from the Catalog](#import-a-source-from-the-catalog).

#### Upload an API spec

{% navtabs "upload-api-spec" %}
{% navtab "API" %}

The `spec` field takes the contents of your OpenAPI spec, in JSON or YAML, as a single string. Build the request body from your spec file with `jq`, replacing `openapi.yaml` with the path to your spec:

```sh
jq -n --rawfile spec openapi.yaml '{
  "name": "flights-api",
  "display_name": "Flights API",
  "description": "Flight search and booking operations",Display name
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

Send a `POST` request to the [`/v1/context-sources` endpoint](/api/konnect/context-interfaces/v1/#/operations/create-context-source) with the request body:

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

{% endnavtab %}
{% endnavtabs %}

#### Add a remote MCP server

{% navtabs "add-mcp-server" %}
{% navtab "API" %}

Send a `POST` request to the [`/v1/context-sources` endpoint](/api/konnect/context-interfaces/v1/#/operations/create-context-source) with the URL of the remote MCP server:

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

{% endnavtab %}
{% endnavtabs %}

### Import a source from the Catalog

{% navtabs "import-source" %}
{% navtab "API" %}

Send a `POST` request to the [`/v1/context-sources` endpoint](/api/konnect/context-interfaces/v1/#/operations/create-context-source):

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-sources
status_code: 201
method: POST
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

{% endnavtab %}
{% endnavtabs %}

### Create the MCP server

{% navtabs "create-mcp-server" %}
{% navtab "API" %}

Send a `POST` request to the [`/v1/context-interfaces` endpoint](/api/konnect/context-interfaces/v1/#/operations/create-context-interface):

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces
status_code: 201
method: POST
body:
  display_name: Travel Assistant
  name: travel-assistant
  description: Flight and booking context for travel agents
  labels: {}
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "UI" %}

{% endnavtab %}
{% endnavtabs %}

### Map the sources to the MCP server

{% navtabs "map-sources" %}
{% navtab "API" %}

Send a `POST` request to the [`/v1/context-interfaces/{interfaceId}/context-source-mappings` endpoint](/api/konnect/context-interfaces/v1/#/operations/create-context-interface-source-mapping) for each source:

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
> To block capabilities on a mapping, send a `POST` request to the [`/v1/context-interfaces/{interfaceId}/context-source-mappings/{mappingId}/capability-controls` endpoint](/api/konnect/context-interfaces/v1/#/operations/create-context-interfaces-source-mapping-capability-controls).
> Use `PATCH` on the same endpoint to change them later. Omitted deny keys keep their existing value, an empty array clears a capability, and a non-empty array replaces it.

{% endnavtab %}
{% navtab "UI" %}

{% endnavtab %}
{% endnavtabs %}

### Deploy the MCP server

Deploy the MCP server by mapping it to a control plane.

{% navtabs "deploy-mcp-server" %}
{% navtab "API" %}

Send a `POST` request to the [`/v1/context-interfaces/{interfaceId}/control-plane-mappings` endpoint](/api/konnect/context-interfaces/v1/#/operations/create-context-interface-control-plane-mapping):

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

### Check the deployment status = remove and use pods checks

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

To review the Python code {{site.context_mesh}} generates for the MCP server, send a `GET` request to the [`/v1/mcp-cp/{controlPlaneId}/mcp-servers/{interfaceId}/code` endpoint](/api/konnect/context-interfaces/v1/#/operations/get-mcp-server-code).

{% endnavtab %}
{% navtab "UI" %}

{% endnavtab %}
{% endnavtabs %}

### Block capabilities

You block capabilities on a source mapping, not on the source itself. To get the mapping ID, send a `GET` request to the [`/v1/context-interfaces/{interfaceId}/context-source-mappings` endpoint](/api/konnect/context-interfaces/v1/#/operations/list-context-interface-source-mappings).

{% navtabs "block-capabilities" %}
{% navtab "API source" %}

Send a `POST` request to the [`/v1/context-interfaces/{interfaceId}/context-source-mappings/{mappingId}/capability-controls` endpoint](/api/konnect/context-interfaces/v1/#/operations/create-context-interfaces-source-mapping-capability-controls). Each operation is a path and the methods to block on that path:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$INTERFACE_ID/context-source-mappings/$MAPPING_ID/capability-controls
status_code: 201
method: POST
body:
  type: api
  deny:
    operations:
      - path: /flights
        methods:
          - PUT
          - DELETE
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "MCP server source" %}

Send a `POST` request to the [`/v1/context-interfaces/{interfaceId}/context-source-mappings/{mappingId}/capability-controls` endpoint](/api/konnect/context-interfaces/v1/#/operations/create-context-interfaces-source-mapping-capability-controls). You must include `tools`, `resources`, and `prompts`. Use an empty array for any you don't want to block:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$INTERFACE_ID/context-source-mappings/$MAPPING_ID/capability-controls
status_code: 201
method: POST
body:
  type: mcp_server
  deny:
    tools:
      - listFlights
    resources:
      - flight-schedule.json
    prompts: []
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% endnavtabs %}

To change blocked capabilities later, send a `PATCH` request to the [same endpoint](/api/konnect/context-interfaces/v1/#/operations/patch-context-interfaces-source-mapping-capability-controls) with the `type` and the `deny` keys you want to change:
* Omitted keys keep their existing value.
* An empty array clears that capability.
* A non-empty array replaces the existing list.

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$INTERFACE_ID/context-source-mappings/$MAPPING_ID/capability-controls
status_code: 200
method: PATCH
body:
  type: mcp_server
  deny:
    prompts:
      - summarize-booking
{% endkonnect_api_request %}
<!--vale on-->

To see the current blocked capabilities, send a `GET` request to the [same endpoint](/api/konnect/context-interfaces/v1/#/operations/get-context-interfaces-source-mapping-capability-controls).
