---
title: 'Datakit'
name: 'Datakit'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: Datakit is a workflow engine for working with external APIs
products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: datakit.png

categories:
  - transformations

related_resources:
  - text: Get started with Datakit
    url: /how-to/get-started-with-datakit/

min_version:
  gateway: '3.11'

tags:
  - transformations
---

The {{site.base_gateway}} Datakit plugin allows you to interact with third-party APIs.
It sends requests to third-party APIs, then uses the response data to seed information for subsequent calls, either upstream or to other APIs.

Datakit allows you to create an API workflow, which can include:
* Making calls to third-party APIs
* Transforming or combining API responses
* Modifying client requests and upstream service responses
* Adjusting {{site.base_gateway}} entity configuration
* Returning directly to users instead of proxying

## Use cases for Datakit

The following are examples of common use cases for Datakit:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: usecase
  - title: Description
    key: description
rows:
  - usecase: "[Third-Party Auth](/plugins/datakit/examples/authenticate-third-party/)"
    description: Use internal auth within your ecosystem to inject request headers before proxying a request.
  - usecase: "[Request Multiplexing](/plugins/datakit/examples/combine-two-apis-into-one-response/)"
    description: Make requests to multiple APIs and combine their responses into one response.
  - usecase: "[Manipulate Request Headers](/plugins/datakit/examples/manipulate-request-headers/)"
    description: Use the Datakit plugin to dynamically adjust request headers before passing them to a third-party service.
{% endtable %}
<!--vale on-->

## Datakit flow editor

In addition to the standard [{{site.base_gateway}} configuration tools](/tools/),
{{site.konnect_short_name}} provides a drag-and-drop flow editor for Datakit. 
The flow editor helps you visualize node connections, inputs, and outputs.

![Full screen flow editor](/assets/images/konnect/datakit-flow-editor-node.png)
> _Figure 1: The Datakit flow editor opens in a full screen with a list of nodes, a drag-and-drop diagram, and detailed configuration options for each node._

You can find the editor through [API Gateway](https://cloud.konghq.com/gateway-manager/) > select your control plane > Plugins > New Plugin > Datakit. 
From here, you can configure Datakit in one of two ways:
* Using the visual flow editor
* Using the code editor

Any changes you make in one editor are reflected in the other. 
For instance, if you have a YAML configuration for Datakit that you want to visualize, you can add it to the code editor, then switch to the flow editor to see it in flow format.

![Flow editor preview](/assets/images/konnect/datakit-flow-editor-preview.png)
> _Figure 2: Toggle the Datakit plugin configuration to the Flow Editor to edit configuration using drag-and-drop. The flow editor shows a preview of the diagram, which you can click to edit in a full screen._

![Code editor](/assets/images/konnect/datakit-code-editor.png)
> _Figure 3: Toggle the Datakit plugin configuration to the Code Editor to edit configuration in YAML format._

### Using the Datakit flow editor 

To configure Datakit using the flow editor:

1. From the {{site.konnect_short_name}} menu, open [**API Gateway**](https://cloud.konghq.com/gateway-manager/).
1. Select your control plane, then in the side menu, go to **Plugins**.
1. Click **New Plugin** and select Datakit. 
1. In the Plugin Configuration section, click **Go to flow editor**.
1. In the editor, drag any node from the menu onto the canvas to add it to your flow, or click **Examples** and choose a pre-configured example to customize.
1. Expand the `inputs` or `outputs` on a node to see the options, then connect a specific input or output to another node.
1. Select any node to open its detailed configuration in a slide-out menu.
1. Fill out the configuration. Any changes to inputs or outputs will be reflected in the diagram.
1. Click **Done** to save.

{:.info}
> **Notes:** 
* Each input can connect to only one output, but one output can accept many inputs.
* Your nodes don't have to connect to the prepopulated `request`/`service request`, or `response`/`service response` nodes. 
Whether you need them or not depends on your use case. Check out the **Examples** dropdown in the editor for some variations.

## How does the Datakit plugin work?

The following sections describes what Datakit nodes are and how they work.

### The node object

The core component of Datakit is the `node` object. A `node` represents some
task that consumes input data, produces output data, or a combination of the two. 
Datakit nodes can:

* Read client request attributes
* Send an external HTTP request
* Modify the response from an upstream before sending it to the client

Most of these tasks can be performed in isolation by an existing plugin. 
Datakit can string together an execution plan from several nodes, connecting the output from one into the input of another:

* Read client request attributes _and_ use them to craft an external HTTP request
* Send an external HTTP request _and_ use the response to augment the service request before proxying upstream
* Modify the response from an upstream _then_ send it to the client using a custom jq filter to enrich the response with data from a third-party API

The following diagram shows how Datakit can be used to combine two third-party API calls into one response:

<!--vale off-->
{% mermaid %}
sequenceDiagram
    actor Client
    participant Datakit
    participant Cat facts API
    participant Dog facts API

    Client->>Datakit: Send a request to the <br/>/animal-fact API endpoint
    Datakit->>Cat facts API: Calls the third-party <br/> /cat-facts API endpoint
    Datakit->>Dog facts API: Calls the third-party <br/> /dog-facts API endpoint
    Cat facts API->>Datakit: Sends a cat fact
    Dog facts API->>Datakit: Sends a dog fact
    Datakit->>Client: Uses jq to join and pass <br/>both facts in a response
{% endmermaid %}
<!--vale on-->

### Node I/O

A Datakit node consumes data via `inputs` and emits data via `outputs`.
Connecting the output of one node to the input of another is accomplished by
referencing the node's unique `name` in the plugin's configuration.

For example, the following snippet establishes a connection from `GET_PROPERTY -> FILTER`, where
`GET_PROPERTY` is the source node, and `FILTER` is the target node:

```yaml
# fetch the value of `my_property` from the shared request context, if it exists
- name: GET_PROPERTY
  type: property
  property: kong.ctx.shared.my_property

- name: FILTER
  type: jq
  jq: "."
  # connect the output of `GET_PROPERTY` to the input of the `FILTER` jq node
  input: GET_PROPERTY
```

Connections can also be reflexively defined in terms of the source node. The following
configuration will yield an execution plan with the same `GET_PROPERTY -> FILTER`
connection:

```yaml
# fetch the value of `my_property` from the shared request context, if it exists
- name: GET_PROPERTY
  type: property
  property: kong.ctx.shared.my_property
  # connect the output of `GET_PROPERTY` to the input of the `FILTER` jq node
  output: FILTER

- name: FILTER
  type: jq
  jq: "."
```

Some nodes have structured, object-like inputs and outputs that can be
referenced by their field name in an I/O label. For example, 
the following configuration allows sending different outputs of `API` to entirely different nodes:

```yaml
- name: API
  type: call
  url: https://example.com/my-json-api

- name: FILTER_BODY
  type: jq
  jq: "."
  # this node only receives the response body from the `API` node
  input: API.body

- name: FILTER_HEADERS
  type: jq
  jq: "."
  # this node only receives the respone headers from the `API` node
  input: API.headers
```

Another way to express this type of connection is by using the `outputs` property
on the source node to select a target node for each named output:

```yaml
- name: API
  type: call
  url: https://example.com/my-json-api
  outputs:
    body: FILTER_BODY
    headers: FILTER_HEADERS

- name: FILTER_BODY
  type: jq
  jq: "."

- name: FILTER_HEADERS
  type: jq
  jq: "."
```

Node outputs can be copied to any number of inputs, but each input may only be
connected to one output. This configuration is correct:

```yaml
- name: GET_FOO
  type: property
  property: kong.ctx.shared.foo

- name: FILTER_FOO
  type: jq
  jq: "."
  input: GET_FOO

- name: FILTER_FOO_TOO
  type: jq
  jq: "."
  input: GET_FOO
```

But this configuration will yield an error for `GET_BAR.output`:

```yaml
- name: GET_FOO
  type: property
  property: kong.ctx.shared.foo
  output: FILTER

- name: GET_BAR
  type: property
  property: kong.ctx.shared.bar
  output: FILTER

- name: FILTER
  type: jq
  jq: "."
```

Error:
```
invalid connection ("GET_BAR" -> "FILTER"): conflicts with existing connection ("GET_FOO" -> "FILTER")
```
{:.no-copy-code}

The `jq` node is especially flexible, allowing you to craft an ad-hoc input
object by defining individual input fields in your configuration. Here's an
alternate version of that last configuration that actually works:

```yaml
- name: GET_FOO
  type: property
  property: kong.ctx.shared.foo

- name: GET_BAR
  type: property
  property: kong.ctx.shared.bar

- name: COMBINE
  type: jq
  # jq will be fed an object with fields `foo` and `bar`
  inputs:
    foo: GET_FOO
    bar: GET_BAR
  jq: ".foo * .bar"
```

Connecting the output of a node to the input of another node establishes a
dependency relationship. Datakit always ensures that a node doesn't run until
its dependencies are satisfied, which means that nodes don't even need to be in
the right order in your configuration:

```yaml
- name: GET_FOO
  type: property
  property: kong.ctx.shared.foo

# this node won't be executed until after `GET_FOO` _and_ `GET_BAR`
- name: COMBINE
  type: jq
  # jq will be fed an object with fields `foo` and `bar`
  inputs:
    foo: GET_FOO
    bar: GET_BAR
  jq: ".foo * .bar"

- name: GET_BAR
  type: property
  property: kong.ctx.shared.bar
```

Order of execution is *not* strictly defined by your configuration.

Configuration order _is_ a facet in determining execution order, 
but don't rely on your configuration to dictate the exact order in which nodes will be executed, 
as Datakit can and will re-order nodes to optimize its execution plan.

#### Data types, validation, and connection semantics

A key component of Datakit is its type system. Datakit supports the following types:

* Primitive, scalar types like `string`s and `number`s
* Non-scalar container types:
    * `object`: Statically-defined, struct-like values
    * `map`: Dynamic string keys and static or dynamically typed values
* Dynamic types:
    * `any`: Values whose type may not be known until runtime

Datakit performs validation at "config-time" (when the plugin is created
or updated via the admin API) by inspecting the type info on either side of a
connection, falling back to runtime checks when necessary:

* If the input and output have the same type (for example, `string -> string`, 
`any -> any`), the connection is permitted since data compatibility at runtime is
    guaranteed
* If the input type can be converted to the output type, runtime compatibility
  isn't guaranteed, but the connection is permitted with an additional runtime
    check to ensure that a node doesn't receive invalid input data. For example:
    * `string -> number`
    * `number -> string`
    * `any -> number`
    * `any -> string`
    * `any -> object`
    * `any -> map`
* If the input type and output type are known to be incompatible (for example,
    `number -> object`), the connection isn't permitted

Connection labels can be in the form of `{node_name}` or `{node_name}.{field_name}`. 
Connections without a field name are referred to in this reference as "node-wise" or `$self` connections.

##### object -> object

For this type of connection, Datakit iterates over each field that the nodes have in common and connects them. 
If the nodes have no fields in common, a validation error will be raised.

For example:

```yaml
# note: don't copy this example. This is a "valid" configuration from Datakit's
# perspective but performs a nonsensical action of copying response headers from
# `api_call` as request headers to `service_request`
- name: api_call
  type: call
  url: "https://example.com/"
  method: POST
  input: request
  output: service_request
```

This results in 5 connections:

* `request.body -> api_call.body`
* `request.query -> api_call.query`
* `request.headers -> api_call.headers`
* `api_call.body -> service_request.body`
* `api_call.headers -> service_request.headers`

All of the `request` node outputs directly map to `api_call` node inputs, but in the
`api_call -> service_request` connection, some fields remain unconnected:

* `api_call.status` is ignored because `service_request` has no `status` input
* `service_request.query` is ignored because `api_call` has no `query` output

The same intent can be expressed explicitly by setting individual fields on the `inputs` attribute:

```yaml
- name: api_call
  type: call
  url: "https://example.com/"
  method: POST
  inputs:
    body: request.body
    query: request.query
    headers: request.headers
  outputs:
    body: service_request.body
    headers: service_request.headers
```

{:.warning}
> Be careful when using this type of connection.
Implicit `object` connections like this one are dynamically expanded after
reading the configuration, so a newly-added field in a subsequent Datakit
release may be inherited by a configuration from a previous version and lead to
unintended behavior changes. 

##### object -> map

This type of connection is not permitted.

```yaml
- name: invalid
  type: call
  url: https://example.com/
  output: service_request.headers
```

Error:
```
invalid connection ("invalid" -> "service_request.headers"): type mismatch: object -> map
```
{:.no-copy-code}

##### object -> any

This type of connection copies all data from the source `object` to the target
input. In this example, `filter` will receive a JSON object as input with the
keys `body`, `query`, and `headers`:

```yaml
- name: filter
  type: jq
  input: request
  jq: "."
```

{:.warning}
> Be careful when using this type of connection.
Implicit `object` connections like this one are dynamically expanded after
reading the configuration, so a newly-added field in a subsequent Datakit
release may be inherited by a configuration from a previous version and lead to
unintended behavior changes. 

##### * -> any

Connections of any output type to an `any` input type are always permitted. At
runtime the data is copied as-is.

##### any -> *

Connections from `any` output types are permitted under almost all conditions
and incur a runtime type conversion check (unless the target type is also `any`).

A node-wise `any -> object` or `any -> map` connection conflicts with
any field-level connections:

```yaml
- name: get-foo
  type: property
  property: kong.ctx.shared.foo
  # connect `get-foo -> response`
  output: response

- name: get-bar
  type: property
  property: kong.ctx.shared.bar
  # Datakit can't validate that this connection will not overlap with
  # `get-foo -> response`
  output: response.body
```

Error:
```
invalid connection ("get-bar" -> "response.body"): conflicts with existing connection ("get-foo" -> "response.body")
```
{:.no-copy-code}

## Node types

The Datakit plugin provides the following node types:

* `call`: Send third-party HTTP calls.
* `jq`: Transform data and cast variables with `jq` to be shared with other nodes.
* `exit`: Return directly to the client.
* `property`: Get and set {{site.base_gateway}}-specific data.
* `static`: Configure static input values ahead of time.

<!--vale off-->
{% table %}
columns:
  - title: Node type
    key: nodetype
  - title: Inputs
    key: inputs
  - title: Outputs
    key: outputs
  - title: Attributes
    key: attributes
rows:
  - nodetype: "`call`"
    inputs: "`body`, `headers`, `query`"
    outputs: "`body`, `headers`, `status`"
    attributes: "`url`, `method`, `timeout`, `ssl_server_name`"
  - nodetype: "`jq`"
    inputs: user-defined
    outputs: user-defined
    attributes: "`jq`"
  - nodetype: "`exit`"
    inputs: "`body`, `headers`"
    outputs: none
    attributes: "`status`"
  - nodetype: "`property`"
    inputs: "`$self`"
    outputs: "`$self`"
    attributes: "`property`, `content_type`"
  - nodetype: "`static`"
    inputs: none
    outputs: user-defined
    attributes: "`values`"
{% endtable %}
<!--vale on-->

### Implicit nodes

Datakit also defines a number of implicit nodes that can be used without being
explicitly declared. These reserved node names can't be used for user-defined
nodes. They include:

<!--vale off-->
{% table %}
columns:
  - title: Node
    key: node
  - title: Inputs
    key: inputs
  - title: Outputs
    key: outputs
  - title: Description
    key: description
rows:
  - node: "`request`"
    inputs: none
    outputs: "`body`, `headers`, `query`"
    description: Reads incoming client request properties
  - node: "`service_request`"
    inputs: "`body`, `headers`, `query`"
    outputs: none
    description: Updates properties of the request sent to the service being proxied to
  - node: "`service_response`"
    inputs: none
    outputs: "`body`, `headers`"
    description: Reads response properties from the service being proxied to
  - node: "`response`"
    inputs: "`body`, `headers`"
    outputs: none
    description: Updates properties of the outgoing client response
{% endtable %}
<!--vale off-->

#### Headers

The `headers` type produces and consumes maps from header names to their values:

* Keys are header names. Original header name casing is preserved for maximum
    compatibility.
* Values are strings if there is a single instance of a header or arrays of
    strings if there are multiple instances of the same header.

#### Query

The `query` type produces and consumes maps with key-value pairs representing
decoded URL query strings.

#### Body

The `service_request.body` and `response.body` inputs both accept any data type.
If the data is an object, it will automatically be JSON-encoded, and the
`Content-Type` header set to `application/json` (if not already set in the
`headers` input).

The `request.body` and `service_response.body` outputs have a similar behavior.
If the corresponding `Content-Type` header matches the JSON mime-type, the
`body` output is automatically JSON-decoded.

### `call` node

Send an HTTP request and retrieve the response.

Inputs:

* `body`: Request body
* `headers`: Request headers
* `query`: Key-value pairs to encode as the request query string

Outputs:

* `body`: The response body
* `headers`: The response headers
* `status`: The HTTP status code of the response

Configuration attributes:

* `url` (**required**): The URL
* `method`: The HTTP method (default is `GET`)
* `timeout`: The dispatch timeout, in milliseconds

#### Examples

Make an external API call:

```yaml
- name: CALL
  type: call
  url: https://example.com/foo
```

Send a POST request with a JSON body:

```yaml
- name: POST
  type: call
  url: https://example.com/create-entity
  method: POST
  inputs:
    body: ENTITY

- name: ENTITY
  type: static
  values:
    id: 123
    name: Datakit
```

#### Automatic JSON body handling

If the data connected to the `body` input is an object, it will automatically be
encoded as JSON, and the request `Content-Type` header will be set to
`application/json` unless already present in the `headers` input.

Similarly, if the response `Content-Type` header matches the JSON mime-type, the
`body` output will be JSON-decoded automatically.

#### Async execution

This is an `async` node. This means that the request will be sent in the
background while Datakit executes any other nodes (save for any nodes which
depend on it). Multiple call nodes are executed concurrently when no dependency
order enforces it.

In this example, both `CALL_FOO` and `CALL_BAR` will be started as soon as
possible, and then Datakit will block until both have finished to run
`JOIN`:

```yaml
- name: CALL_FOO
  type: call
  url: https://example.com/foo

- name: CALL_BAR
  type: call
  url: https://example.com/bar

- name: JOIN
  type: jq
  jq: "."
  inputs:
    foo: CALL_FOO.body
    bar: CALL_BAR.body
```

#### Failure conditions

The `call` node fails execution if a network-level error is encountered or if
the endpoint returns a non-2xx status code. It will also fail if the endpoint
returns a JSON mime-type in the `Content-Type` header if the response body is
not valid JSON.

#### Limitations

Due to platform limitations, the `call` node can't be executed after proxying a
request, so attempting to configure the node using outputs from the upstream service
response will yield an error:

```yaml
- name: CALL
  type: call
  url: https://example.com/
  method: POST
  inputs:
    # dependency error!
    body: service_response.body
```

Error:
```
invalid dependency (node #1 (CALL) -> node service_response): circular dependency
```
{:.no-copy-code}

### `jq` node type

The `jq` node executes a jq script for processing JSON. See the official
[jq docs](https://jqlang.org/) for more details.

#### Inputs

User-defined. For node-wise (`$self`) connections, `jq` can handle input of
_any_ type:

```yaml
- name: SERVICE
  type: property
  property: kong.router.service

- name: IP
  type: property
  property: kong.client.ip

- name: FILTER_SERVICE
  type: jq
  input: SERVICE
  # yields: "object"
  jq: ". | type"

- name: FILTER_IP
  type: jq
  input: IP
  # yields: "string"
  jq: ". | type"
```

By defining individual `inputs`, `jq`'s input will be coerced to an object with
string keys and values of any type. Referencing input fields from within the
filter is done by using dot (`.`) notation:

```yaml
- name: SERVICE
  type: property
  property: kong.router.service

- name: IP
  type: property
  property: kong.client.ip

- name: FILTER_SERVICE_AND_IP
  type: jq
  inputs:
    service: SERVICE
    ip: IP
  # yields: { "$self": "object", "service": "object", "ip": "string" }
  jq: |
    {
      "$self":   (.        | type),
      "service": (.service | type),
      "ip":      (.ip      | type)
    }
```

#### Outputs

User-defined. A `jq` filter script can produce _any_ type of data:

```yaml
- name: STRING
  type: jq
  jq: |
    "my string"

- name: NUMBER
  type: jq
  jq: |
    54321

- name: BOOLEAN
  type: jq
  jq: |
    true

- name: OBJECT
  type: jq
  jq: |
    {
      a: 1,
      b: 2
    }
```

It's impossible for Datakit to know ahead of time what kind of data `jq` will
emit, so Datakit uses runtime checks when the output of `jq` is connected to
another node's input. It's important to carefully test and validate your Datakit
configurations to avoid this case:

```yaml
- name: HEADERS
  type: jq
  jq: |
    "oops, not an object/map"

- name: EXIT
  type: exit
  inputs:
    # this will cause Datakit to return a 500 error to the client when
    # encountered
    headers: HEADERS
```

This is also why the `jq` node doesn't allow explicitly referencing individual
fields with `outputs` at config-time:

```yaml
- name: HEADERS
  type: jq
  jq: |
    "this is completely opaque to Datakit"

  # Datakit will reject this configuration because it can't confirm that the
  # output of HEADERS is an object or has a `body` field
  outputs:
    body: EXIT.body

- name: EXIT
  type: exit
```

#### Configuration attributes

`jq`: the jq script to execute when the node is triggered.


#### Handling HTTP headers in jq

To enable a high level of transparency and compatibility when
communicating with external services, `headers` outputs in Datakit always
preserve the original case of header names. While HTTP-centric nodes within
Datakit are careful to account for this and perform header lookups and
transformations in a case-insensitive manner, `jq` at its core is a library for
operating upon JSON data, and JSON object keys are strictly case-sensitive.

Be mindful of this when handling headers in a `jq` filter to avoid buggy, error-prone behavior. 
For example:

```yaml
# adds the `X-Extra` header to the upstream service request if not set by the client
- name: ADD_HEADERS
  type: jq
  input: request.headers
  output: service_request.headers
  jq: |
    {
      "X-Extra": ( .["X-Extra"] // "default value" ),
    }
```

This filter will function correctly if the client sets the `X-Extra` header or
omits it entirely, but it won't have the intended effect if the client sets
the header `X-EXTRA` or `x-extra`.

`jq` lets you write a robust filter that handles this condition. 
The following implementation normalizes header names to lowercase before looking up values from the input:

```yaml
# adds the `X-Extra` header to the upstream service request if not set by the client
- name: ADD_HEADERS
  type: jq
  input: request.headers
  output: service_request.headers
  jq: |
    with_entries(.key |= ascii_downcase)
    | {
        "X-Extra": ( .["x-extra"] // "default value" ),
    }
```

##### Recipe: merging header objects

These examples take in client request headers and update them from a set of
pre-defined values.

The [HTTP specification RFC](https://datatracker.ietf.org/doc/html/rfc2616)
defines header names to be case-insensitive, so in most cases it's 
enough to normalize header names to lowercase for ease of merging the
two objects:

```yaml
- name: header_updates
  type: static
  values:
    X-Foo: "123"
    X-Custom: "my header"
    X-Multi:
      - "first"
      - "second"

- name: merged_headers
  type: jq
  inputs:
    original: request.headers
    updates: header_updates
  jq: |
    (.original | with_entries(.key |= ascii_downcase))
    *
    (.updates | with_entries(.key |= ascii_downcase))

- name: api
  type: call
  url: "https://example.com/"
  inputs:
    headers: merged_headers
```

However, when dealing with a upstream service or API that isn't fully compliant
with the HTTP spec, it might be necessary to preserve original header name
casing. For example:

```yaml
- name: header_updates
  type: static
  values:
    X-Foo: "123"
    X-Custom: "my header"
    X-Multi:
      - "first"
      - "second"

- name: merged_headers
  type: jq
  inputs:
    original: request.headers
    updates: header_updates
  jq: |
    . as $input

    # store .original key names for lookup
    | $input.original
    | with_entries({ key: .key | ascii_downcase, value: .key })
      as $keys

    # rewrite .updates with .original key names
    | $input.updates
    | with_entries(.key = ($keys[.key | ascii_downcase] // .key))
      as $updates

    | $input.original * $updates

- name: api
  type: call
  url: "https://example.com/"
  inputs:
    headers: merged_headers
```

#### Examples

Coerce the client request body to an object:

```yaml
- name: BODY
  type: jq
  input: request.body
  jq: |
    if type == "object" then
      .
    else
      { data: . }
    end
```

Join the output of two API calls:

```yaml
- name: FOO
  type: call
  url: https://example.com/foo

- name: BAR
  type: call
  url: https://example.com/bar

- name: JOIN
  type: jq
  inputs:
    foo: FOO.body
    bar: BAR.body
  jq: "."
```

### `exit` node

Trigger an early exit that produces a direct response, rather than forwarding
a proxied response.

Inputs:

* `body`: Body to use in the early-exit response.
* `headers`: Headers to use in the early-exit response.

Outputs: None

Configuration attributes:

* `status`: The HTTP status code to use in the early-exit response (default is
  `200`).

#### Examples

Make an HTTP request and send the response directly to the client:

```yaml
- name: CALL
  type: call
  url: https://example.com/

- name: EXIT
  type: exit
  input: CALL
```

### `property` node

Get and set {{site.base_gateway}} host and request properties.

Whether a `get` or `set` operation is performed depends upon the node inputs:

* If an input is connected, `set` the property
* If no input is connected, `get` the property and map it to the output

#### Inputs

This node accepts the `$self` input:

```yaml
- name: STORE_REQUEST
  type: property
  property: kong.ctx.shared.my_request
  input: request
```

No individual field-level inputs are permitted:

```yaml
- name: STORE_REQUEST_BY_FIELD
  type: property
  property: kong.ctx.shared.my_request
  # error! property input doesn't allow field access
  inputs:
    body: request.body
```

#### Outputs

This node produces the `$self` output.

```yaml
- name: GET_ROUTE
  type: property
  property: kong.router.route
  output: response.body
```

Field-level output connections are not supported, even if the output data has known fields:

```yaml
- name: GET_ROUTE_ID
  type: property
  property: kong.router.route
  # error! property output doesn't allow field access
  outputs:
    id: response.body
```

#### Configuration attributes

* `property` (**required**): The name of the property
* `content_type`: The expected mime type of the property value. When set to
    `application/json`, `set` operations will JSON-encode input data before
    writing it, and `get` operations will JSON-decode output data after
    reading it. Otherwise, this setting has no effect.

#### Supported properties

The following properties support **get** operations:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: desc
  - title: Data type
    key: type
rows:
  - property: "`kong.client.consumer`"
    desc: "`kong.client.get_consumer()`"
    type: "`object`"

  - property: "`kong.client.consumer_groups`"
    desc: "`kong.client.get_consumer_groups()`"
    type: "`array`"

  - property: "`kong.client.credential`"
    desc: "`kong.client.get_credential()`"
    type: "`object`"

  - property: "`kong.client.get_identity_realm_source`"
    desc: "`kong.client.get_identity_realm_source()`"
    type: "`object`"

  - property: "`kong.client.forwarded_ip`"
    desc: "`kong.client.get_forwarded_ip()`"
    type: "`string`"

  - property: "`kong.client.forwarded_port`"
    desc: "`kong.client.get_forwarded_port()`"
    type: "`number`"

  - property: "`kong.client.ip`"
    desc: "`kong.client.get_ip()`"
    type: "`string`"

  - property: "`kong.client.port`"
    desc: "`kong.client.get_port()`"
    type: "`number`"

  - property: "`kong.client.protocol`"
    desc: "`kong.client.get_protocol()`"
    type: "`string`"

  - property: "`kong.request.forwarded_host`"
    desc: "`kong.request.get_forwarded_host()`"
    type: "`string`"

  - property: "`kong.request.forwarded_port`"
    desc: "`kong.request.get_forwarded_port()`"
    type: "`number`"

  - property: "`kong.request.forwarded_scheme`"
    desc: "`kong.request.get_forwarded_scheme()`"
    type: "`string`"

  - property: "`kong.request.port`"
    desc: "`kong.request.get_port()`"
    type: "`number`"

  - property: "`kong.response.source`"
    desc: "`kong.response.get_source()`"
    type: "`string`"

  - property: "`kong.router.route`"
    desc: "`kong.router.get_route()`"
    type: "`object`"

  - property: "`kong.route_id`"
    desc: Gets the current Route's ID
    type: "`string`"

  - property: "`kong.route_name`"
    desc: Gets the current Route's name
    type: "`string`"

  - property: "`kong.router.service`"
    desc: "`kong.router.get_service()`"
    type: "`object`"

  - property: "`kong.service_name`"
    desc: Gets the current Service's name
    type: "`string`"

  - property: "`kong.service_id`"
    desc: Gets the current Service's ID
    type: "`string`"

  - property: "`kong.service.response.status`"
    desc: "`kong.service.response.status`"
    type: "`number`"

  - property: "`kong.version`"
    desc: Gets the Kong version
    type: "`string`"

  - property: "`kong.node.id`"
    desc: "`kong.node.get_id()`"
    type: "`string`"

  - property: "`kong.configuration.{key}`"
    desc: Reads `{key}` from the node configuration
    type: "`any`"

{% endtable %}
<!--vale on-->

The following properties support `set` operations:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: desc
  - title: Data type
    key: type
rows:
  - property: "`kong.service.target`"
    desc: "`kong.service.set_target({host}, {port})`"
    type: "`string` (`{host}:{port}`)"

  - property: "`kong.service.request_scheme`"
    desc: "`kong.service.set_service_request_scheme({scheme})`"
    type: "`string` (`{scheme}`)"
{% endtable %}
<!--vale on-->

The following properties support `get` and `set` operations:

<!--vale off-->
{% table %}
columns:
  - title: Property
    key: property
  - title: Description
    key: desc
  - title: Data type
    key: type
rows:
  - property: "`kong.ctx.plugin.{key}`"
    desc: "`Gets or sets kong.ctx.plugin.{key}`"
    type: "`any`"

  - property: "`kong.ctx.shared.{key}`"
    desc: "`Gets or sets kong.ctx.shared.{key}`"
    type: "`any`"
{% endtable %}
<!--vale on-->

### `static` node

Emits static values to be used as inputs for other nodes. The `static` node can help you with hardcoding some known value for an input.

#### Inputs

None.

#### Outputs

This node produces outputs for each item in its `values` attribute:

```yaml
- name: CALL_INPUTS
  type: static
  values:
    headers:
      X-Foo: "123"
      X-Multi:
        - first
        - second
    query:
      a: true
      b: 10
    body:
      data: "my request body data"

- name: CALL
  type: call
  url: https://example.com/
  method: POST
  input: CALL_INPUTS
```

The static nature of these values comes in handy, because Datakit can
validate them when creating or updating the plugin configuration. Attempting to
create a plugin with the following configuration will yield an Admin API
validation error _instead_ of bubbling up at runtime:

```yaml
- name: CALL_INPUTS
  type: static
  values:
    headers: "oops not valid headers"

- name: CALL
  type: call
  url: https://example.com/
  method: POST
  input: CALL_INPUTS
```

#### Configuration attributes

* `values` (**required**): A mapping of string keys to arbitrary values

#### Examples

Set a property from a static value:

```yaml
- name: VALUE
  type: static
  values:
    data:
      a: 1
      b: 2

- name: PROPERTY
  type: property
  property: kong.ctx.shared.my_property
  input: VALUE.data
```

Set a default value for a `jq` filter:

```yaml
- name: VALUE
  type: static
  values:
    default: "my default value"

- name: FILTER
  type: jq
  inputs:
    query: request.query
    default: VALUE.default
  jq: ".query.foo // .default"
```

Set common request headers for different API requests:

```yaml
- name: HEADERS
  type: static
  values:
    X-Common: "we always need this header"

- name: CALL_FOO
  type: call
  url: https://example.com/foo
  inputs:
    headers: HEADERS

- name: CALL_BAR
  type: call
  url: https://example.com/bar
  inputs:
    headers: HEADERS
```

## Debugging

Datakit includes support for debugging your configuration.

{:.warning}
> Enabling the `debug` option in Datakit is considered unsafe for production
environments, as it can cause arbitrary information to leak into client
responses.

### Making node execution errors visible

When a Datakit node encounters an error, the default behavior is to exit
immediately with a generic 500 error so as not to leak any information to the
client:

```json
{
  "message": "An unexpected error occurred",
  "request_id": "f5e07609d55bd66508c8315b8cf6583a"
}
```

You can find the entire error in the {{site.base_gateway}} `error.log` file:

```
> 2025/06/24 10:55:32 [error] 917449#0: *1292 [lua] runtime.lua:406: handler(): node #1 (API) failed with error: "non-2XX response code: 403", client: 127.0.0.1, server: kong, request: "GET / HTTP/1.1", host: "test-010.datakit.test", request_id: "f5e07609d55bd66508c8315b8cf6583a"
```

For quicker feedback during local development and testing, the error can also be
passed through to the client response by enabling the `debug` option in your
Datakit plugin configuration. In addition to the full error message, the
response contains information about the node which failed, including the node
name, type, and index (the position of the node within the `nodes` array in your
plugin configuration):

```json
{
  "message": "node execution error",
  "request_id": "f5e07609d55bd66508c8315b8cf6583a",
  "error": "non-2XX response code: 403",
  "node": {
    "index": 1,
    "name": "API",
    "type": "call"
  }
}
```

### Execution debug tracing

With `debug` enabled in the plugin configuration, add the
`X-DataKit-Debug-Trace` header with a value of `"true"`, `"yes"`, `"on"`, `"1"`,
or `"enabled"` to prompt Datakit to perform detailed execution tracing and return
a full report in the client response.

Here's an example where the `API` node failed due to its endpoint returning a
`403` status code. The failure caused all pending/running node tasks to be
canceled and resulted in an execution plan error (`PLAN_ERROR`):

```json
{
  "started_at": 1750789142.703118,
  "status": "PLAN_ERROR",
  "ended_at": 1750789142.705158,
  "nodes": [
    {
      "name": "API",
      "type": "call",
      "status": "NODE_ERROR",
      "error": "non-2XX response code: 403"
    },
    {
      "name": "SLOW_API",
      "status": "NODE_CANCELED",
      "type": "call"
    },
    {
      "name": "FILTER",
      "status": "NODE_CANCELED",
      "type": "jq"
    },
    {
      "name": "request",
      "status": "NODE_COMPLETE",
      "type": "request"
    }
  ],
  "duration": 0.002039670944213867,
  "events": [
    {
      "name": "request",
      "action": "run",
      "values": [],
      "type": "request",
      "at": 0.00001406669616699219
    },
    {
      "name": "request",
      "action": "complete",
      "values": [
        {
          "type": "any",
          "key": "headers"
        },
        {
          "type": "any",
          "key": "body"
        },
        {
          "type": "map",
          "value": {
            "b": "123",
            "a": "true"
          },
          "key": "query"
        }
      ],
      "type": "request",
      "at": 0.0000324249267578125
    },
    {
      "name": "API",
      "action": "run",
      "values": [
        {
          "type": "map",
          "key": "headers"
        },
        {
          "type": "any",
          "key": "body"
        },
        {
          "type": "map",
          "value": {
            "b": "123",
            "a": "true"
          },
          "key": "query"
        }
      ],
      "type": "call",
      "at": 0.00003552436828613281
    },
    {
      "type": "call",
      "action": "run",
      "at": 0.00005054473876953125,
      "name": "API"
    },
    {
      "name": "SLOW_API",
      "action": "run",
      "values": [
        {
          "type": "map",
          "key": "headers"
        },
        {
          "type": "any",
          "key": "body"
        },
        {
          "type": "map",
          "value": {
            "b": "123",
            "a": "true"
          },
          "key": "query"
        }
      ],
      "type": "call",
      "at": 0.00005173683166503906
    },
    {
      "type": "call",
      "action": "run",
      "at": 0.00005674362182617188,
      "name": "SLOW_API"
    },
    {
      "name": "API",
      "action": "resume",
      "type": "call",
      "at": 0.001984357833862305,
      "duration": 0.001933813095092773
    },
    {
      "name": "API",
      "action": "fail",
      "values": [
        {
          "type": "error",
          "value": "non-2XX response code: 403"
        },
        {
          "type": "map",
          "value": {
            "Connection": "keep-alive",
            "X-Powered-By": "mock_upstream",
            "Content-Length": "824",
            "Content-Type": "application/json",
            "Date": "Tue, 24 Jun 2025 18:19:02 GMT",
            "Server": "mock-upstream/1.0.0"
          },
          "key": "headers"
        },
        {
          "type": "any",
          "value": {
            "url": "http://127.0.0.1:15555/status/403?b=123&a=true",
            "post_data": {
              "params": null,
              "text": "",
              "kind": "unknown"
            },
            "code": 403,
            "vars": {
              "host": "127.0.0.1",
              "request_method": "GET",
              "binary_remote_addr": "\u007f\u0000\u0000\u0001",
              "uri": "/status/403",
              "request_time": "0.000",
              "remote_addr": "127.0.0.1",
              "request_length": "119",
              "remote_port": "50902",
              "scheme": "http",
              "ssl_server_name": "no SNI",
              "hostname": "soup",
              "request_uri": "/status/403?b=123&a=true",
              "server_port": "15555",
              "server_name": "mock_upstream",
              "request": "GET /status/403?b=123&a=true HTTP/1.1",
              "server_protocol": "HTTP/1.1",
              "https": "",
              "realip_remote_addr": "127.0.0.1",
              "server_addr": "127.0.0.1",
              "realip_remote_port": "50902",
              "is_args": "?"
            },
            "uri_args": {
              "b": "123",
              "a": "true"
            },
            "headers": {
              "user-agent": "lua-resty-http/0.17.2 (Lua) ngx_lua/10028",
              "host": "127.0.0.1:15555"
            }
          },
          "key": "body"
        },
        {
          "type": "number",
          "value": 403,
          "key": "status"
        }
      ],
      "type": "call",
      "at": 0.00200200080871582
    },
    {
      "name": "SLOW_API",
      "action": "cancel",
      "type": "call",
      "at": 0.002033710479736328,
      "duration": 0.001976966857910156
    },
    {
      "type": "jq",
      "action": "cancel",
      "at": 0.002036333084106445,
      "name": "FILTER"
    }
  ]
}
```

The tracing output is emitted _instead of_ any other pending client
response body (originating from Datakit or elsewhere), so there are limits to
what can be observed in the trace. The `response` node, for instance, can't
execute fully when tracing is enabled and will appear in the tracing report with
a result of `NODE_SKIPPED`.

{:.warning}
> The contents of the tracing report are unstable and intended for human
consumption to aid development and testing. Backwards-incompatible changes to
the report format _may_ be included with any new release of
{{site.base_gateway}}.
