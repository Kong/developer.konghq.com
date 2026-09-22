---
title: Control MCP tool access with AI Consumer and AI Consumer Group ACLs
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
  - text: AI Consumer entity
    url: /ai-gateway/entities/ai-consumer/
  - text: AI Consumer Group entity
    url: /ai-gateway/entities/ai-consumer-group/
  - text: AI Auth Strategy entity
    url: /ai-gateway/entities/ai-auth-strategy/
  - text: Map a RESTful API to MCP tools
    url: /ai-gateway/map-api-to-mcp-tools/
  - text: Observe MCP traffic with the File Log Policy
    url: /ai-gateway/observe-mcp-traffic/

description: Learn how to create an AI MCP Server entity in {{site.ai_gateway}} to restrict access to specific MCP tools based on AI Consumers and AI Consumer Groups. Configure default and per-tool ACLs, define user roles, and validate access behavior with the MCP Inspector CLI.

products:
  - ai-gateway

series:
  id: mcp-acls-2-1
  position: 1

permalink: /ai-gateway/use-access-controls-for-mcp-tools/

works_on:
  - konnect

min_version:
  ai-gateway: '2.1'

entities:
  - ai-mcp-server
  - ai-consumer
  - ai-consumer-group
  - ai-auth-strategy

tags:
  - ai
  - mcp
  - security

tldr:
  q: How do I control access to MCP tools using {{site.ai_gateway}}?
  a: |
    Use the [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) entity to control access to MCP tools with default and per-tool ACLs based on AI Consumers and AI Consumer Groups.

    This tutorial converts the Swagger Petstore API into MCP tools, authenticates callers with a `key-auth` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/), then gates each tool by AI Consumer Group membership and by individual AI Consumer.

tools:
  - kongctl

faqs:
  - q: Why does a denied tool call fail at the transport layer instead of returning a JSON-RPC error?
    a: |
      An ACL denial is enforced on the route, before the request is dispatched as an MCP RPC, so {{site.ai_gateway}} returns a plain `HTTP 403 Forbidden` response rather than a JSON-RPC error object. The MCP Inspector CLI surfaces this as a `Streamable HTTP error` and exits with a non-zero status. An MCP client that assumes every response is JSON-RPC needs to handle the status code itself.
  - q: Why does `tools/list` succeed for a blocked AI Consumer instead of failing?
    a: |
      Tool discovery and tool invocation are evaluated separately. Discovery filters the list down to the tools the AI Consumer is allowed to reach, so a fully blocked AI Consumer gets an `HTTP 200` response with an empty `tools` array instead of an outright rejection. Invoking a tool directly is what returns `HTTP 403 Forbidden`.
  - q: Why does a per-tool ACL have to repeat groups that `access.default_tool_acls` already allows?
    a: |
      A per-tool ACL replaces the default for that tool, it doesn't merge with it. When a tool defines its own `access.acls`, {{site.ai_gateway}} ignores `access.default_tool_acls` for that tool entirely, so the tool's `allow` list must name every subject that should reach it. See [How default and per-tool ACLs work](/ai-gateway/entities/ai-mcp-server/#how-default-and-per-tool-acls-work).

prereqs:
  inline:
    - title: Petstore API
      include_content: prereqs/third-party/swagger-petstore

cleanup:
  inline:
    - title: Stop Petstore API
      include_content: cleanup/third-party/swagger-petstore
    - title: Clean up {{site.ai_gateway}} resources
      include_content: cleanup/products/ai-gateway
      icon_url: '/assets/icons/ai-gateway.svg'
---

## Create AI Consumer Groups for each access tier

Configure [AI Consumer Groups](/ai-gateway/entities/ai-consumer-group/) that reflect access levels. These groups govern MCP tool permissions:

- `admin`: full access, including destructive tools
- `support`: read-only access to pet and store data
- `suspended`: blocked from MCP tools

{% entity_examples %}
ai_gateway_consumer_groups:
  - ref: admin
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Admin
    name: admin
    policies: []
  - ref: support
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Support
    name: support
    policies: []
  - ref: suspended
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Suspended
    name: suspended
    policies: []
{% endentity_examples %}

## Create AI Consumers

1. Configure individual AI Consumers and add them to their groups. Each one inherits the ACL rules of its group, and Eason, who belongs to no group, is only reachable through the tool-level ACLs you'll set in the next section:

{% capture consumers %}
{% entity_examples %}
ai_gateway_consumers:
  - ref: alice
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Alice
    name: alice
    type: api-key
    policies: []
  - ref: bob
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Bob
    name: bob
    type: api-key
    policies: []
  - ref: carol
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Carol
    name: carol
    type: api-key
    policies: []
  - ref: eason
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    display_name: Eason
    name: eason
    type: api-key
    policies: []
ai_gateway_consumer_groups:
  - ref: admin
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: admin
    display_name: Admin
    policies: []
    consumers:
      - !ref alice#name
  - ref: support
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: support
    display_name: Support
    policies: []
    consumers:
      - !ref bob#name
  - ref: suspended
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: suspended
    display_name: Suspended
    policies: []
    consumers:
      - !ref carol#name
{% endentity_examples %}
{% endcapture %}

{{ consumers | indent }}

1. Export each AI Consumer's ID as an environment variable using `kongctl get`. The credential requests that follow identify each consumer by ID, not by name:

   ```bash
   export ALICE_ID=$(kongctl get ai-gateway consumers --gateway-id "$AI_GATEWAY_ID" alice --output json --jq '.id' -r)
   export BOB_ID=$(kongctl get ai-gateway consumers --gateway-id "$AI_GATEWAY_ID" bob --output json --jq '.id' -r)
   export CAROL_ID=$(kongctl get ai-gateway consumers --gateway-id "$AI_GATEWAY_ID" carol --output json --jq '.id' -r)
   export EASON_ID=$(kongctl get ai-gateway consumers --gateway-id "$AI_GATEWAY_ID" eason --output json --jq '.id' -r)
   ```

1. Create an API key credential for Alice, and save the generated key. {{site.ai_gateway}} generates the key value; it isn't set by you and can't be retrieved again after this step:

{% capture alice_credential %}
<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$ALICE_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Alice key
  name: alice-key
  type: api-key
extract_body:
  - name: 'api_key'
    variable: ALICE_API_KEY
capture:
  - variable: ALICE_API_KEY
    command: "jq -r '.api_key'"
{% endkonnect_api_request %}
<!-- vale on -->
{% endcapture %}

{{ alice_credential | indent }}

1. Create an API key credential for Bob:

{% capture bob_credential %}
<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$BOB_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Bob key
  name: bob-key
  type: api-key
extract_body:
  - name: 'api_key'
    variable: BOB_API_KEY
capture:
  - variable: BOB_API_KEY
    command: "jq -r '.api_key'"
{% endkonnect_api_request %}
<!-- vale on -->
{% endcapture %}

{{ bob_credential | indent }}

1. Create an API key credential for Carol:

{% capture carol_credential %}
<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$CAROL_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Carol key
  name: carol-key
  type: api-key
extract_body:
  - name: 'api_key'
    variable: CAROL_API_KEY
capture:
  - variable: CAROL_API_KEY
    command: "jq -r '.api_key'"
{% endkonnect_api_request %}
<!-- vale on -->
{% endcapture %}

{{ carol_credential | indent }}

1. Create an API key credential for Eason:

{% capture eason_credential %}
<!-- vale off -->
{% konnect_api_request %}
url: /v1/ai-gateways/$AI_GATEWAY_ID/consumers/$EASON_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
  - 'Accept: application/json, application/problem+json'
body:
  display_name: Eason key
  name: eason-key
  type: api-key
extract_body:
  - name: 'api_key'
    variable: EASON_API_KEY
capture:
  - variable: EASON_API_KEY
    command: "jq -r '.api_key'"
{% endkonnect_api_request %}
<!-- vale on -->
{% endcapture %}

{{ eason_credential | indent }}

## Configure the AI MCP Server

Configure the [AI MCP Server](/ai-gateway/entities/ai-mcp-server/) to convert the Petstore API into MCP tools and apply tool-level access rules. Access is determined by AI Consumer Groups and individual AI Consumers using `allow` and `deny` lists. A tool ACL replaces the default rule when present.

The following table shows the effective permissions for this configuration:

<!-- vale off -->
{% table %}
columns:
  - title: MCP tool
    key: tool
  - title: Admin group
    key: admin
  - title: Support group
    key: support
  - title: Eason consumer
    key: eason
  - title: Suspended group
    key: suspended
rows:
  - tool: "`get-pets-by-status`"
    admin: Yes
    support: Yes
    eason: Yes
    suspended: No
  - tool: "`get-pet-by-id`"
    admin: Yes
    support: Yes
    eason: No
    suspended: No
  - tool: "`get-inventory`"
    admin: Yes
    support: Yes
    eason: No
    suspended: No
  - tool: "`get-order-by-id`"
    admin: Yes
    support: Yes
    eason: No
    suspended: No
  - tool: "`delete-pet`"
    admin: Yes
    support: No
    eason: No
    suspended: No
{% endtable %}
<!-- vale on -->

Apply the following configuration to configure:
* A `key-auth` [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) so each AI Consumer presents their key in the `apikey` header
* The AI MCP Server, its converted Petstore tools, and their ACL rules

{% entity_examples %}
ai_gateway_auth_strategies:
  - ref: my-key-auth
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: my-key-auth
    display_name: "my-key-auth"
    type: key-auth
    config:
      key_names:
        - apikey
      key_in_header: true
      key_in_query: false
ai_gateway_mcp_servers:
  - ref: petstore-acl-mcp
    ai_gateway: !lookup {id: !env AI_GATEWAY_ID}
    name: petstore-acl-mcp
    display_name: "Petstore API"
    type: conversion-listener
    enabled: true
    policies: []
    access:
      auth_strategies:
        - !ref my-key-auth#name
      acl_attribute_type: consumer
      acls:
        allow: []
      default_tool_acls:
        allow:
          - admin
        deny: []
    config:
      url: http://host.docker.internal:8080/api/v3
      route:
        paths:
          - /petstore-acl
      logging:
        payloads: false
      server:
        timeout: 60000
    tools:
      - name: get-pets-by-status
        description: Find pets by status
        method: GET
        path: /petstore-acl/pet/findByStatus
        access:
          acls:
            allow:
              - admin
              - support
              - eason
        parameters:
          - name: status
            in: query
            required: true
            schema:
              type: string
              enum:
                - available
                - pending
                - sold
            description: Status value to filter pets by
      - name: get-pet-by-id
        description: Get a pet by ID
        method: GET
        path: /petstore-acl/pet/{petId}
        access:
          acls:
            allow:
              - admin
              - support
        parameters:
          - description: ID of the pet to retrieve
            in: path
            name: petId
            required: true
            schema:
              type: integer
      - name: get-inventory
        description: Get pet inventories by status
        method: GET
        path: /petstore-acl/store/inventory
        access:
          acls:
            allow:
              - admin
              - support
      - name: get-order-by-id
        description: Get a purchase order by ID
        method: GET
        path: /petstore-acl/store/order/{orderId}
        access:
          acls:
            allow:
              - admin
              - support
        parameters:
          - description: ID of the order to retrieve
            in: path
            name: orderId
            required: true
            schema:
              type: integer
      - name: delete-pet
        description: Delete a pet
        method: DELETE
        path: /petstore-acl/pet/{petId}
        access:
          acls:
            allow:
              - admin
            deny:
              - support
        parameters:
          - description: ID of the pet to delete
            in: path
            name: petId
            required: true
            schema:
              type: integer
{% endentity_examples %}

{:.info}
> `suspended` has no per-tool ACL entry anywhere, so Carol falls through to `access.default_tool_acls`, which only allows `admin`. This blocks her from every tool without needing an explicit `deny`.

`access.acls` is the server-level gate, evaluated before any tool ACL. Every AI Consumer passes it here: an empty `allow` list means no server-level rule is configured, so access is decided entirely by `access.default_tool_acls` and the per-tool ACLs. Populate `access.acls` when you want to block an AI Consumer from the AI MCP Server as a whole, rather than from individual tools.

Because this is a `conversion-listener`, {{site.ai_gateway}} builds each tool's input schema from its `parameters` list, prefixing every parameter name with its `in` location. The `status` query parameter is exposed to MCP clients as `query_status`, and the `petId` and `orderId` path parameters as `path_petId` and `path_orderId`.

## Validate

Validate the ACL rules with the [MCP Inspector CLI](https://modelcontextprotocol.io/docs/tools/inspector#cli), passing each AI Consumer's API key in the `apikey` header. The set of tools each AI Consumer can discover and call reflects their group membership.

### Alice sees and can call every tool

Alice is in `admin`, which `access.default_tool_acls` allows and every tool's `allow` list names, so she discovers all five tools:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore-acl \
    --transport http --method tools/list \
    --header "apikey: $ALICE_API_KEY" | jq -r '.tools[].name' | sort
expected:
  return_code: 0
  message: |
    delete-pet
    get-inventory
    get-order-by-id
    get-pet-by-id
    get-pets-by-status
render_output: false
{% endvalidation %}
<!--vale on-->

You should see the following output:

```text
delete-pet
get-inventory
get-order-by-id
get-pet-by-id
get-pets-by-status
```
{:.no-copy-code}

Calling `delete-pet`, the only tool restricted to `admin`, also succeeds:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore-acl \
    --transport http --method tools/call \
    --tool-name delete-pet \
    --tool-arg path_petId=10 \
    --header "apikey: $ALICE_API_KEY"
expected:
  return_code: 0
  message: "Pet deleted"
render_output: false
{% endvalidation %}
<!--vale on-->

The tool result confirms the deletion with `Pet deleted`.

### Bob can read, but not delete

Bob is in `support`, which is on the `deny` list for `delete-pet`. Tool discovery filters that tool out, so he sees only four:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore-acl \
    --transport http --method tools/list \
    --header "apikey: $BOB_API_KEY" | jq -r '.tools[].name' | sort
expected:
  return_code: 0
  message: |
    get-inventory
    get-order-by-id
    get-pet-by-id
    get-pets-by-status
render_output: false
{% endvalidation %}
<!--vale on-->

You should see the following output:

```text
get-inventory
get-order-by-id
get-pet-by-id
get-pets-by-status
```
{:.no-copy-code}

The tools he can reach work as normal. Calling `get-pet-by-id` returns `Lion 1`:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore-acl \
    --transport http --method tools/call \
    --tool-name get-pet-by-id \
    --tool-arg path_petId=7 \
    --header "apikey: $BOB_API_KEY" | jq -r '.content[0].text' | jq -c '.'
expected:
  return_code: 0
  message: |
    {"id":7,"category":{"id":4,"name":"Lions"},"name":"Lion 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
render_output: false
{% endvalidation %}
<!--vale on-->

You should see the following response:

```text
{"id":7,"category":{"id":4,"name":"Lions"},"name":"Lion 1","photoUrls":["url1","url2"],"tags":[{"id":1,"name":"tag1"},{"id":2,"name":"tag2"}],"status":"available"}
```
{:.no-copy-code}

Invoking `delete-pet` directly confirms the same rule that filtered it out of his tool list. The call is rejected with `HTTP 403 Forbidden`, which the MCP Inspector CLI reports as a transport error and a non-zero exit code:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore-acl \
    --transport http --method tools/call \
    --tool-name delete-pet \
    --tool-arg path_petId=9 \
    --header "apikey: $BOB_API_KEY"
expected:
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

You should see output similar to the following:

```text
Failed to call tool delete-pet: Streamable HTTP error: Error POSTing to endpoint: ...403 Forbidden...
```
{:.no-copy-code.wrap}

### Carol is blocked from every tool

Carol is in `suspended`, which no tool allows and `access.default_tool_acls` doesn't include, so her `tools/list` succeeds but returns an empty list:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore-acl \
    --transport http --method tools/list \
    --header "apikey: $CAROL_API_KEY" | jq '.tools | length'
expected:
  return_code: 0
  message: "0"
render_output: false
{% endvalidation %}
<!--vale on-->

Invoking a tool directly is what returns `HTTP 403 Forbidden`:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore-acl \
    --transport http --method tools/call \
    --tool-name get-inventory \
    --header "apikey: $CAROL_API_KEY"
expected:
  return_code: 1
render_output: false
{% endvalidation %}
<!--vale on-->

### Eason only has access to the pet catalogue

Eason belongs to no AI Consumer Group, but the `get-pets-by-status` tool's own `access.acls.allow` names him directly, alongside `admin` and `support`. Every other tool falls back to `access.default_tool_acls`, which doesn't include him, so he sees a single tool:

<!--vale off-->
{% validation custom-command %}
command: |
  npx -y @modelcontextprotocol/inspector@0.22.0 --cli \
    http://localhost:8000/petstore-acl \
    --transport http --method tools/list \
    --header "apikey: $EASON_API_KEY" | jq -r '.tools[].name' | sort
expected:
  return_code: 0
  message: |
    get-pets-by-status
render_output: false
{% endvalidation %}
<!--vale on-->

You should see the following output:

```text
get-pets-by-status
```
{:.no-copy-code}

This is how an individual AI Consumer can be granted an exception without creating an AI Consumer Group for them, and why a tool ACL has to name every subject it allows: `get-pets-by-status` lists `admin` explicitly, because its own ACL replaced `access.default_tool_acls` rather than extending it.
