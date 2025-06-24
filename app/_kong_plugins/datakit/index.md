---
title: 'Datakit'
name: 'Datakit'

content_type: plugin

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
* Making calls to third party APIs
* Transforming or combining API responses
* Modifying client requests and service responses
* Adjusting Kong entity configuration
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
    description: Use internal auth within your ecosystem by sending response headers to upstreams.
  - usecase: "[Request Multiplexing](/plugins/datakit/examples/combine-two-apis-into-one-response/)"
    description: Make requests to multiple APIs and combine their responses into one response.
  - usecase: "[Manipulate Request Headers](/plugins/datakit/examples/manipulate-request-headers/)"
    description: Use the Datakit plugin to dynamically adjust request headers before passing them to a third-party service.
{% endtable %}
<!--vale on-->

## How does the Datakit plugin work?

### The `node` object

The core component of Datakit is the `node` object. A `node` represents some
task that consumes input data, produces output data, or a combination of the
two. Datakit nodes can:

* read client request attributes
* send an external HTTP request
* modify the response from an upstream before sending it to the client

Most of these tasks can be performed in isolation by an existing plugin. The
power of Datakit stems from being able to string together an execution plan from
several nodes, connecting the output from one into the input of another:

* read client request attributes _**and use them to craft an external HTTP
    request**_
* send an external HTTP request _**and use the response to augment the service
    request before proxying upstream**_
* modify the response from an upstream before sending it to the client
    _**using a custom jq filter to enrich the response with data from a
    third-party API**_

The following diagram shows how Datakit can be used to combine two third-party
API calls into one response:

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

A datakit node consumes data via `inputs` and emits data via `outputs`. Linking
the output of one node to the input of another is accomplished by referencing
the node's unique `name` in the plugin's configuration:

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

I/O links can be reflexively defined, so this configuration will yield the same
execution plan:

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
referenced by their field name in an I/O label. Note how this allows sending
different outputs of `API` to entirely different nodes:

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

Another way to express this type of linkage is by using the `outputs` property
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
connected to one output. This configuration is okay:

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

...but this configuration will yield an error:

```yaml
- name: GET_FOO
  type: property
  property: kong.ctx.shared.foo
  output: FILTER

- name: GET_BAR
  type: property
  property: kong.ctx.shared.bar
  # error! the input of `FILTER` is already connected
  output: FILTER

- name: FILTER
  type: jq
  jq: "."
```

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
  jq: ".foo * .bar"
  # jq will be fed an object with fields `.foo` and `.bar`
  inputs:
    foo: GET_FOO
    bar: GET_BAR
```

Connecting the output of a node to the input of another node establishes a
dependency relationship. Datakit always ensures that a node does not run until
its dependencies are satisfied, which means that nodes don't even need to be in
the right order in your configuration:

```yaml
- name: GET_FOO
  type: property
  property: kong.ctx.shared.foo

# this node won't be executed until after `GET_FOO` _and_ `GET_BAR`
- name: COMBINE
  type: jq
  jq: ".foo * .bar"
  # jq will be fed an object with fields `.foo` and `.bar`
  inputs:
    foo: GET_FOO
    bar: GET_BAR

- name: GET_BAR
  type: property
  property: kong.ctx.shared.bar
```

While that example isn't particularly useful for crafting your datakit
configuration, it serves to demonstrate an important facet of datakit's runtime
behavior: **order of execution is NOT strictly defined by your configuration.**
As of this writing, configuration order _is_ a facet in determining execution
order, but in a general sense it is unsound to rely on your configuration to
dictate the exact order in which nodes will be executed, as datakit can and will
re-order nodes to optimize its execution plan.

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
  - node: request
    inputs: none
    outputs: "`body`, `headers`, `query`"
    description: The incoming request
  - node: "`service_request`"
    inputs: "`body`, `headers`, `query`"
    outputs: none
    description: Request sent to the service being proxied to
  - node: "`service_response`"
    inputs: none
    outputs: "`body`, `headers`"
    description: Response sent by the service being proxied to
  - node: "`response`"
    inputs: "`body`, `headers`"
    outputs: none
    description: Response to be sent to the incoming request
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

#### Input ports

* `body`: request body
* `headers`: request headers
* `query`: key-value pairs to encode as the request query string

#### Output ports

* `body`: the response body
* `headers`: the response headers
* `status`: the HTTP status code of the response

#### Configuration attributes

* `url` (**required**): the URL
* `method`: the HTTP method (default is `GET`)
* `timeout`: the dispatch timeout, in milliseconds

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
possible, and then Datakit will block until both have finished in order to run
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

Due to platform limitations, the `call` node cannot be executed after proxying a
request, so attempting to configure the node using outputs from the service
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

### `jq` node type

Execution of a jq script for processing JSON. See the official
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
  name: jq
  input: SERVICE
  # yields: "object"
  jq: ". | type"

- name: FILTER_IP
  name: jq
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
  name: jq
  inputs:
    service: SERVICE
    ip: IP
  # yields: { "$self": "object", "service": "object", "ip": "object" }
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
  name: jq
  jq: |
    "my string"

- name: NUMBER
  name: jq
  jq: |
    54321

- name: BOOLEAN
  name: jq
  jq: |
    true

- name: OBJECT
  name: jq
  jq: |
    {
      a: 1,
      b: 2
    }
```

It's impossible for Datakit to know ahead of time what kind of data `jq` will
emit, so Datakit utilizes runtime checks when the output of `jq` is connected to
another node's input. It's important to carefully test and validate your Datakit
configurations to avoid this case:

```yaml
- name: HEADERS
  name: jq
  jq: |
    "oops, not an object/map"

- name: EXIT
  type: exit
  inputs:
    # this will cause Datakit to return a 500 error to the client when
    # encountered
    headers: HEADERS
```

#### Configuration attributes

* `jq`: the jq script to execute when the node is triggered.

#### Examples

Coerece the client request body to an object:

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
  call: https://example.com/foo

- name: BAR
  type: call
  call: https://example.com/bar

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

#### Inputs

* `body`: body to use in the early-exit response.
* `headers`: headers to use in the early-exit response.

#### Outputs

None.

#### Configuration attributes

* `status`: the HTTP status code to use in the early-exit response (default is
  200).

#### Examples

Make an HTTP request and send the response directly to the client:

```yaml
- name: CALL
  type: call
  call: https://example.com/

- name: EXIT
  type: exit
  input: CALL
```
  
### `property` node

Get and set {{site.base_gateway}} host and request properties.

Whether a **get** or **set** operation is performed depends upon the node inputs:

* If an input port is configured, **set** the property
* If no input port is configured, **get** the property and map it to the output

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
  # error! property input does not allow field access
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

Field-level output connections are currently not supported, even if the output
data has known fields:

```yaml
- name: GET_ROUTE_ID
  type: property
  property: kong.router.route
  # error! property output does not allow field access
  outputs:
    id: response.body
```

#### Configuration attributes

* `property` (**required**): the name of the property
* `content_type`: the expected mime type of the property value. When set to
    `application/json`, **set** operations will JSON-encode input data before
    writing it, and **get** operations will JSON-decode output data after
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
    desc: Reads "`{key}` from the node configuration
    type: "`any`"

{% endtable %}
<!--vale on-->

The following properties support **set** operations:

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
    type: "`string` (`{host}:{port}`)

  - property: "`kong.service.request_scheme`"
    desc: "`kong.service.set_service_request_scheme({scheme})`"
    type: "`string` (`{scheme}`)
{% endtable %}
<!--vale on-->

The following properties support **get** and **set** operations:

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

Emits static values to be used as inputs for other nodes. If you are wondering
"how do I hard-code some known value for an input?" then the static node is for
you.

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

The static nature of these values comes in handy, because Datakit can eagerly
validate them when creating/updating the plugin configuration. Attempting to
create a plugin with the following configuration will yield an admin API
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

* `values` (**required**): a mapping of string keys to arbitrary values

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

- name: BAZ_HEADERS
  type: jq
  inputs:
    headers: HEADERS
  jq: |
    . * {
      "X-Baz": "extra header for CALL_BAZ"
    }

- name: CALL_BAZ
  type: call
  url: https://example.com/baz
  inputs:
    headers: BAZ_HEADERS
```

## Debugging

Datakit includes support for debugging your configuration.

{:.warning}
Enabling the `debug` option in Datakit is considered unsafe for production
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

The entire error is included in the `error.log` file for review:

> 2025/06/24 10:55:32 [error] 917449#0: *1292 [lua] runtime.lua:406: handler(): node #1 (API) failed with error: "non-2XX response code: 403", client: 127.0.0.1, server: kong, request: "GET / HTTP/1.1", host: "test-010.datakit.test", request_id: "f5e07609d55bd66508c8315b8cf6583a"

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
canceled and resulted in an execution plan error ("PLAN_ERROR"):

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

Be aware that the tracing output is emited _instead of_ any other pending client
response body (originating from Datakit or elsewhere), so there are limits to
what can be observed in the trace. The `response` node, for instance, cannot
execute fully when tracing is enabled and will appear in the tracing report with
a result of `NODE_SKIPPED`.

{:.warning}
The contents of the tracing report are unstable and intended for human
consumption to aid development and testing. Backwards-incompatible changes to
the report format _may_ be included with any new release of
{{site.base_gateway}}.
