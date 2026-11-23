---
title: "{{site.context_mesh}} MCP servers"
content_type: reference
layout: reference

permalink: /context-mesh/mcp-servers/
description: "Reference for {{site.context_mesh}} MCP servers, including how REST APIs are exposed as Code Mode MCP servers, and how you deploy and configure those servers."

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
  - text: "{{site.context_mesh}} sources"
    url: /context-mesh/sources/
  - text: "{{site.context_mesh}} skills"
    url: /context-mesh/skills/
  - text: "Deploy an MCP server with {{site.context_mesh}} and {{site.operator_product_name}}"
    url: /context-mesh/get-started/
  - text: "{{site.context_mesh}} API reference"
    url: /api/konnect/context-interfaces/v1/
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "{{site.operator_product_name}}"
    url: /operator/
  - text: "Install {{site.operator_product_name}}"
    url: /operator/get-started/konnect-crds/install/
  - text: "{{site.operator_product_name}} version support policy"
    url: /operator/support-policy/
  - text: "Stages of software availability"
    url: /stages-of-software-availability/

faqs:
  - q: What is a Code Mode MCP server?
    a: |
      In [Code Mode](https://gofastmcp.com/servers/transforms/code-mode), the MCP server doesn't list its tools to the agent. Instead, the agent sees a few meta-tools: `search`, `get_schemas`, and `list_tools` to find the tools it needs, and `execute` to run short Python code in a sandbox that calls those tools.
      The agent chains the calls in code, and only the final result returns to the context window.
      This lets an agent work with a large API surface without flooding the model's context. {{site.context_mesh}} generates all of its MCP servers in Code Mode.
  - q: Can I add auth to a {{site.context_mesh}} MCP server?
    a: |
      Not on the MCP server itself. You can set [custom headers on a source](/context-mesh/sources/#custom-headers), and {{site.context_mesh}} attaches them to every request it sends to that source's backing service.
      However, {{site.context_mesh}} stores custom headers unencrypted, so you can't use them for credentials such as API keys, bearer tokens, or passwords.
---

{{site.context_mesh}} lets you turn enterprise assets (like MCP servers and APIs) into context that AI agents can call. It works by composing those assets, also called [sources](/context-mesh/sources/), into a single deployable [Code Mode](https://blog.cloudflare.com/code-mode/) MCP server.r. You can attach [skills](/context-mesh/skills/) to the server to give agents reusable instructions alongside the tools.

## What are {{site.context_mesh}} MCP servers

{{site.context_mesh}} MCP servers are the result of bundling different sources together and deploying them as a single Code Mode MCP server. This becomes the source of truth for your agents after you deploy them on a {{site.konnect}} [control plane](/gateway/control-plane-groups/).

Each {{site.context_mesh}} MCP server inherits the capabilities listed in each one of its sources as follows:

* **API sources:** each operation in the OpenAPI spec (a path and a method, for example `/flight` and `GET`) becomes a capability. {{site.context_mesh}} generates Python code that registers each API operation as an MCP tool. For example, an API source's `GET /flights` operation becomes a `listFlights` tool.
* **MCP server sources:** {{site.context_mesh}} inherits the tools the remote MCP server already exposes and proxies them. You can't define additional tools on the source from {{site.context_mesh}}.

### How agents use a Code Mode MCP server

{{site.context_mesh}} generates every MCP server in Code Mode. The tools from your sources exist on the server, but the server doesn't list them to the agent. Instead of calling these tools directly, agents find them with the Code Mode meta-tools and call them from code. The agent sees the following meta-tools:

{% table %}
columns:
  - title: Meta-tool
    key: tool
  - title: What it does
    key: description
rows:
  - tool: "`list_tools`"
    description: Returns the full catalog of tools from all sources at once.
  - tool: "`search`"
    description: Finds tools by keyword or natural-language query.
  - tool: "`get_schemas`"
    description: Returns the parameters of specific tools.
  - tool: "`execute`"
    description: Runs Python code written by the agent in a sandbox. Inside the sandbox, the code calls the tools from your sources and chains their results.

{% endtable %}

To complete a task, the agent discovers the tools it needs, then writes one script that calls them with `execute`. Only the final result of the script returns to the model's context window, instead of every intermediate response. The sandbox limits how long the code can run and how much memory it can use.

When you create a {{site.context_mesh}} MCP server, you configure it with the following parameters:

{% feature_table %}
item_title: Parameter
columns:
  - title: Description
    key: description
  - title: Required
    key: required
features:
  - title: "Sources"
    description: "[{{site.context_mesh}} sources](/context-mesh/sources/) you've previously added."
    required: true
  - title: "Display name"
    description: MCP server's name in the UI.
    required: true
  - title: "Name"
    description: |
      Machine name. Must be unique within the org. Auto-populated from the **Display name**.
    required: true
  - title: "Description"
    description: The {{site.context_mesh}} MCP server description.
    required: false
  - title: "Labels"
    description: Key-value tags for filtering/searching across {{site.konnect}}. In the API, send `{}` if you don't want to add any labels.
    required: Only with the API

{% endfeature_table %}

You can deploy the {{site.context_mesh}} MCP server at creation or later.

## Blocked capabilities

By default, a {{site.context_mesh}} MCP server inherits everything a [source](/context-mesh/sources/) can do. For example, if an API source contains 20 operations, the {{site.context_mesh}} MCP server that uses it gives the agent access to the 20 operations. The same applies to all the tools a remote MCP server source exposes.

**Blocked capabilities** let you restrict specific paths, methods, and tools without changing the source itself. They block source items on one {{site.context_mesh}} MCP server, so agents can't access the blocked items through that server. Other MCP servers that use the same source aren't affected.

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


## Deployments

To run the {{site.context_mesh}} MCP server, you deploy it on a {{site.konnect}} Control Plane.
You can deploy a {{site.context_mesh}} MCP server in two modes. Both modes require {{site.operator_product_name}} on the control plane. To install it, see [Install {{site.operator_product_name}}](/operator/get-started/konnect-crds/install/).

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
  - mode: |
      **Advanced** {% assign tp = site.data.stages.tech_preview %}{% include badge.html url=tp.url text=tp.text css_class="bg-semantic-yellow-secondary text-semantic-yellow-primary" %}
    description: |
      You control the deployment directly with [{{site.operator_product_name}}](/operator/) custom resources instead of using the {{site.konnect_short_name}} defaults.

{% endtable %}
{:.success}
> Use Basic mode unless you need to control the Kubernetes workload.
>
> Use Advanced mode when you need to set the replica count, CPU and memory resources, or custom labels and annotations on the deployment.
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

You can see this status in the {{site.konnect_short_name}} UI. To check the deployment outside the UI, check the MCP server pod in your cluster instead. {{site.operator_product_name}} runs each {{site.context_mesh}} MCP server as a deployment with the `mcpserver-` prefix. To confirm the pod is running, replace `NAMESPACE` with your namespace and run the following command with [kubectl](https://kubernetes.io/docs/reference/kubectl/):

```sh
kubectl get pods -n NAMESPACE | grep mcpserver
```

A healthy MCP server shows `1/1` ready with the `Running` status. For example:

```text
mcpserver-test-45675cb3-764b4d6d6c-q2gnp   1/1     Running   0   57m
```
{:.no-copy-code}

If the pod stays in `Pending` or `CrashLoopBackOff`, check its logs with `kubectl logs -n NAMESPACE POD_NAME`.

To review the Python code {{site.context_mesh}} generates for the MCP server, send a `GET` request to the [Get generated Python code for the MCP Server](/api/konnect/context-interfaces/v1/#/operations/get-mcp-server-code) endpoint.

For the full deployment flow, see [Deploy an MCP server with {{site.context_mesh}} and {{site.operator_product_name}}](/context-mesh/get-started/).

## Set up a {{site.context_mesh}} MCP server

Setting up a {{site.context_mesh}} MCP server is a multi-step process. [Add your sources](/context-mesh/sources/#add-a-source) first, then create the MCP server and map each source to it. Deploying to a control plane is the final step. To give agents reusable instructions, you can also [add a skill](/context-mesh/skills/#add-a-skill).

{:.info}
> The [{{site.context_mesh}} API](/api/konnect/context-interfaces/v1/) uses `/v1/context-interfaces` for {{site.context_mesh}} MCP servers. Wherever the endpoints refer to a context interface, that is a {{site.context_mesh}} MCP server.

### Create the MCP server


{% navtabs "create-mcp-server" %}
{% navtab "API" %}

Send a `POST` request to the [Create a Context Interface](/api/konnect/context-interfaces/v1/#/operations/create-context-interface) endpoint:

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

1. In the {{site.konnect_short_name}} sidebar, click **{{site.context_mesh}}**.
1. In the {{site.context_mesh}} sidebar, click **MCP Servers**.
1. Click **New MCP server**.
1. In **Add a source**, select as many sources as the context needs.
1. In **MCP server details**, add a **Display name**. The **Name** value auto-fills from it.
1. In **Deploy your MCP server**, select the **API Gateway** control plane on which to deploy, or click **Skip for now**.
{% endnavtab %}
{% endnavtabs %}

### Get the MCP and source IDs

Mapping sources, deploying the MCP server, and adding skills all use the ID of the MCP server. Mapping sources also uses the ID of the source. Get both IDs from the API:

1. Send a `GET` request to the [List all Context Interfaces](/api/konnect/context-interfaces/v1/#/operations/list-context-interfaces) endpoint to list your MCP servers. Find your MCP server in the response and copy its `id`:

   ```sh
   curl -X GET "https://us.api.konghq.com/v1/context-interfaces" \
        --no-progress-meter --fail-with-body \
        -H "Authorization: Bearer $KONNECT_TOKEN" \
        | jq '.data[] | {display_name, name, id}'
   ```

   Export the ID as an environment variable, replacing `YOUR_INTERFACE_ID` with the `id` you copied:

   ```sh
   export INTERFACE_ID='YOUR_INTERFACE_ID'
   ```

1. Send a `GET` request to the [List Context Sources](/api/konnect/context-interfaces/v1/#/operations/list-context-sources) endpoint to list your sources. Find your source in the response and copy its `id`:

   ```sh
   curl -X GET "https://us.api.konghq.com/v1/context-sources" \
        --no-progress-meter --fail-with-body \
        -H "Authorization: Bearer $KONNECT_TOKEN" \
        | jq '.data[] | {display_name, name, id}'
   ```

   Export the ID as an environment variable, replacing `YOUR_SOURCE_ID` with the `id` you copied:

   ```sh
   export SOURCE_ID='YOUR_SOURCE_ID'
   ```

### Map the sources to the MCP server

{% navtabs "map-sources" %}
{% navtab "API" %}

Send a `POST` request to the [Create Context Interface Source Mapping](/api/konnect/context-interfaces/v1/#/operations/create-context-interface-source-mapping) endpoint for each source. This request uses the `INTERFACE_ID` and `SOURCE_ID` environment variables. To get them, see [Get the MCP and source IDs](#get-the-mcp-and-source-ids):

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
> To block capabilities on a mapping, send a `POST` request to the [Create Interface-Source Capability Controls](/api/konnect/context-interfaces/v1/#/operations/create-context-interfaces-source-mapping-capability-controls) endpoint.

{% endnavtab %}
{% navtab "UI" %}

1. In the {{site.konnect_short_name}} sidebar, click **{{site.context_mesh}}**.
1. In the {{site.context_mesh}} sidebar, click **MCP Servers**.
1. Click your MCP server.
1. Click the **Sources** tab.
1. Click **Add sources**.
1. Select the checkbox for each source to add.
1. Click **Add sources**.

{% endnavtab %}
{% endnavtabs %}

### Set up blocked capabilities

You block capabilities on a source mapping, so you need the ID of the mapping between the MCP server and the source. Send a `GET` request to the [List Context Interface Source Mappings](/api/konnect/context-interfaces/v1/#/operations/list-context-interface-source-mappings) endpoint to list the sources mapped to the MCP server. The command saves the ID of the mapping for the source whose ID is in the `SOURCE_ID` environment variable as the `MAPPING_ID` environment variable:

<!--vale off-->
{% konnect_api_request %}
url: /v1/context-interfaces/$INTERFACE_ID/context-source-mappings
status_code: 200
method: GET
capture:
  - variable: MAPPING_ID
    jq: '.data[] | select(.context_source_id == \"$SOURCE_ID\") | .id'
{% endkonnect_api_request %}
<!--vale on-->

{% navtabs "block-capabilities" %}
{% navtab "API source" %}

Send a `POST` request to the [Create Interface-Source Capability Controls](/api/konnect/context-interfaces/v1/#/operations/create-context-interfaces-source-mapping-capability-controls) endpoint. Each operation is a path and the methods to block on that path:

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

Send a `POST` request to the [Create Interface-Source Capability Controls](/api/konnect/context-interfaces/v1/#/operations/create-context-interfaces-source-mapping-capability-controls) endpoint. You must include `tools`, `resources`, and `prompts`. Use an empty array for any you don't want to block:

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

To change blocked capabilities later, send a `PATCH` request to the [Update Interface-Source Capability Controls](/api/konnect/context-interfaces/v1/#/operations/patch-context-interfaces-source-mapping-capability-controls) endpoint with the `type` and the `deny` keys you want to change:
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

To see the current blocked capabilities, send a `GET` request to the [Get Interface-Source Capability Controls](/api/konnect/context-interfaces/v1/#/operations/get-context-interfaces-source-mapping-capability-controls) endpoint.

### Block capabilities from the UI

To set up blocked capabilities from the UI:

1. In the {{site.konnect_short_name}} sidebar, click **{{site.context_mesh}}**.
1. In the {{site.context_mesh}} sidebar, click **MCP Servers**.
1. Click your MCP server.
1. Click the **Sources** tab.
1. In the source list, click a source. A sidebar dialog opens.
1. In **Blocked capabilities**, click **Edit**.
1. In the **Add to blocklist** field, add the API path, or the MCP tools, resources, or prompts you want to block.
1. Select the call method or the tool type.
1. Click **Add**.
1. Click **Save changes**.

### Deploy the MCP server

Deploy the MCP server by mapping it to an existing control plane that has {{site.operator_product_name}} installed on it. To install it, see [Install {{site.operator_product_name}}](/operator/get-started/konnect-crds/install/).

{:.info}
> {{site.operator_product_name}} must run with the {{site.konnect_short_name}} controller enabled (`ENABLE_CONTROLLER_KONNECT=true`) and the `mcp-server` feature gate (`FEATURE_GATES=mcp-server`) to run a {{site.context_mesh}} MCP server. For the full Helm command, see [Install {{site.operator_product_name}}](/context-mesh/get-started/#install-kong-operator) in the get-started guide. For the feature gates option, see the [configuration options](/operator/reference/configuration-options/).

{% navtabs "deploy-mcp-server" %}
{% navtab "API" %}

This section uses the following environment variables:
* `INTERFACE_ID`: the ID of your MCP server. To get it, see [Get the MCP and source IDs](#get-the-mcp-and-source-ids).
* The ID of a control plane managed by {{site.operator_product_name}}.

Send a `GET` request to the [List Control Planes](/api/konnect/control-planes/v2/#/operations/list-control-planes) endpoint. If any of your control planes is managed by {{site.operator_product_name}}, this request returns it:

```sh
curl -X GET "https://us.api.konghq.com/v2/control-planes?labels=k8s-uid" \
     --no-progress-meter --fail-with-body \
     -H "Authorization: Bearer $KONNECT_TOKEN" \
     | jq '.data[] | {name, id}'
```

Select a control plane in the response and copy its `id`. Export the ID as an environment variable, replacing `YOUR_CONTROL_PLANE_ID` with the `id` you copied:

```sh
export CONTROL_PLANE_ID='YOUR_CONTROL_PLANE_ID'
```

Send a `POST` request to the [Create Context Interface CP Mapping](/api/konnect/context-interfaces/v1/#/operations/create-context-interface-control-plane-mapping) endpoint:

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

1. In the {{site.konnect_short_name}} sidebar, click **{{site.context_mesh}}**.
1. In the {{site.context_mesh}} sidebar, click **MCP Servers**.
1. Click your MCP server.
1. Click **Deploy**.
1. From the **Control plane** dropdown menu, select a control plane that is managed by {{site.operator_product_name}}.
1. Select the **Basic** deployment mode.
1. Click **Deploy and finish**.
1. Wait until the MCP server status is **Healthy**.

{% endnavtab %}
{% endnavtabs %}

