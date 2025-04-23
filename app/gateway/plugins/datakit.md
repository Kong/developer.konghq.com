---
title: Datakit
tech_preview: true

layout: reference
content_type: reference

permalink: /plugins/datakit/

related_resources:
  - text: Kong Plugin Hub
    url: /plugins/
  - text: Get started with Datakit
    url: /how-to/get-started-with-datakit/

breadcrumbs:
  - /plugins/

act_as_plugin: true
name: Datakit
publisher: kong-inc
icon: /assets/icons/plug.svg
categories:
  - transformations

description: Send requests to third-party APIs and use the response data to seed information for subsequent calls

works_on:
  - on-prem

products:
  - gateway

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional

min_version:
  gateway: '3.9'

tags:
  - transformations
  - tech-preview

prereqs:
  skip_product: true
---

The {{site.base_gateway}} Datakit is a plugin that allows you to interact with third-party APIs. 
It sends requests to third-party APIs, then uses the response data to seed information for subsequent calls, either upstream or to other APIs. 

Datakit is a data flow engine built on top of the WASM engine within the {{site.base_gateway}}.
It allows you to create an API workflow, which can include:
* Making calls to third party APIs
* Transforming or combining API responses
* Modifying client requests and service responses
* Adjusting Kong entity configuration
* Returning directly to users instead of proxying

{:.warning}
> The Datakit plugin is not available in {{site.base_gateway}} packages by default. 
Before you configure the plugin, you must enable it:
> * **Package install:** Set `wasm=on` in [`kong.conf`](/gateway/configuration/#wasm) before starting {{site.base_gateway}}
> * **Docker:** Set `export WASM=on` in the environment
> * **Kubernetes:** Set `WASM=on` using the [Custom Plugin](/kubernetes-ingress-controller/custom-plugins/) instructions.

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
  - usecase: "[Internal authentication](#authenticate-kong-gateway-to-a-third-party-service)"
    description: Use internal auth within your ecosystem by sending response headers to upstreams.
  - usecase: "[Service callout](#combine-two-apis-into-one-response)"
    description: Reach out to a third-party service, then combine with other requests or augment the original request before sending back to the upstream.
  - usecase: "[Dynamic service discovery](#manipulate-request-headers)"
    description: Integrate seamlessly with third-party APIs that assist with service discovery and set new upstream values dynamically.
  - usecase: "[Get and set Kong entity properties](#adjust-kong-gateway-service-and-route-properties)"
    description: |
      Use Datakit to adjust {{site.base_gateway}} entity configurations. For example, you could replace the service URL or set a header on a route.
{% endtable %}
<!--vale on-->

## How does it work?

The core component of Datakit is a node. Nodes are inputs to other nodes, which creates the execution path for a given Datakit configuration. 

Datakit provides the following node types:
* `call`: Third-party HTTP calls
* `jq`: Transform data and cast variables with `jq` to be shared with other nodes
* `handlebars`: Apply a [Handlebars](https://docs.rs/handlebars/latest/handlebars/) template to a raw string, useful for producing arbitrary non-JSON content types
* `exit`: Return directly to the client
* `property`: Get and set {{site.base_gateway}} configuration data

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

## Configuration reference

Datakit nodes can have input ports and output ports.
Input ports consume data. Output ports produce data.

You can link one node's output port to another node's input port.
An input port can receive at most one link, that is, data can only arrive
into an input via one other node. Therefore, there are no race conditions.

An output port can be linked to multiple nodes. Therefore, one node can
provide data to several other nodes.

Each node triggers at most once.

A node only triggers when data is available to all its connected input ports;
that is, only when all nodes connected to its inputs have finished
executing.

### Node types

The following node types are implemented:

<!--vale off-->
{% table %}
columns:
  - title: Node type
    key: nodetype
  - title: Input ports
    key: input_ports
  - title: Output ports
    key: output_ports
  - title: Supported attributes
    key: supported_attributes
rows:
  - nodetype: "`call`"
    input_ports: "`body`, `headers`, `query`"
    output_ports: "`body`, `headers`"
    supported_attributes: "`url`, `method`, `timeout`"
  - nodetype: "`jq`"
    input_ports: user-defined
    output_ports: user-defined
    supported_attributes: "`jq`"
  - nodetype: "`handlebars`"
    input_ports: user-defined
    output_ports: "`output`"
    supported_attributes: "`template`, `content_type`"
  - nodetype: "`exit`"
    input_ports: "`body`, `headers`"
    output_ports: none
    supported_attributes: "`status`"
  - nodetype: "`property`"
    input_ports: "`value`"
    output_ports: "`value`"
    supported_attributes: "`property`, `content_type`"
{% endtable %}
<!--vale on-->

#### `call` node type

An HTTP dispatch call.

##### Input ports

* `body`: body to use in the dispatch request.
* `headers`: headers to use in the dispatch request.
* `query`: key-value pairs to encode as the query string.

##### Output ports

* `body`: body returned as the dispatch response.
* `headers`: headers returned as the dispatch response.
* `error`: triggered if a dispatch error occurs, such as a DNS resolver timeout, etc.
  The port returns the error message.

##### Supported attributes

* `url` (**required**): the URL to use when dispatching.
* `method`: the HTTP method (default is `GET`).
* `timeout`: the dispatch timeout, in seconds (default is 60).

##### Examples

Make an external API call:

```yaml
- name: CALL
  type: call
  url: https://httpbin.konghq.com/anything
```

#### `jq` node type

Execution of a JQ script for processing JSON. The JQ script is processed
using the [jaq](https://lib.rs/crates/jaq) implementation of the JQ language.

##### Input ports

User-defined. Each input port declared by the user will correspond to a
variable in the JQ execution context. A user can declare the name of the port
explicitly, which is the name of the variable. If a port does not have a given
name, it will get a default name based on the peer node and port to which it
is connected, and the name will be normalized into a valid variable name (e.g.
by replacing `.` to `_`).

##### Output ports

User-defined. When the JQ script produces a JSON value, that is made available
in the first output port of the node. If the JQ script produces multiple JSON
values, each value will be routed to a separate output port.

##### Supported attributes

* `jq`: the JQ script to execute when the node is triggered.

##### Examples

Set a header:
```yaml
- name: MY_HEADERS
  type: jq
  inputs:
  - req: request.headers
  jq: |
    {
      "X-My-Call-Header": $req.apikey // "default value"
      }
```

Join the output of two API calls:

```yaml
- name: JOIN
  type: jq
  inputs:
  - cat: CAT_FACT.body
  - dog: DOG_FACT.body
  jq: |
    {
      "cat_fact": $cat.fact,
      "dog_fact": $dog.facts[0]
    }
```

#### `handlebars` node type

Application of a [Handlebars](https://docs.rs/handlebars/latest/handlebars/) template on a raw string, useful for producing
arbitrary non-JSON content types.

##### Input ports

User-defined. Each input port declared by the user will correspond to a
variable in the Handlebars execution context. A user can declare the name of
the port explicitly, which is the name of the variable. If a port does not
have a given name, it will get a default name based on the peer node and port
to which it is connected, and the name will be normalized into a valid
variable name (e.g. by replacing `.` to `_`).

##### Output ports

* `output`: the rendered template. The output payload will be in raw string
  format, unless an alternative `content_type` triggers a conversion.

##### Supported attributes

* `template`: the Handlebars template to apply when the node is triggered.
* `content_type`: if set to a MIME type that matches one of DataKit's
  supported payload types, such as `application/json`, the output payload will
  be converted to that format, making its contents available for further
  processing by other nodes (default is `text/plain`, which produces a raw
  string).

##### Examples

Create a template for parsing the output of an external API call to a coordinates API:

```yaml
- name: MY_BODY
  type: handlebars
  content_type: text/plain
  inputs:
  - first: FIRST.body
  output: service_request.body
  template: |
    {% raw %}Coordinates for {{ first.places.0.[place name] }}, {{ first.places.0.state }}, {{ first.country }} are ({{ first.places.0.latitude }}, {{ first.places.0.longitude }}){% endraw %}.
```

#### `exit` node type

Trigger an early exit that produces a direct response, rather than forwarding
a proxied response.

##### Input ports

* `body`: body to use in the early-exit response.
* `headers`: headers to use in the early-exit response.

##### Output ports

None.

##### Supported attributes

* `status`: the HTTP status code to use in the early-exit response (default is
  200).

##### Examples

Exit and pass the input directly to the client:

```yaml
- name: EXIT
  type: exit
  inputs:
  - body: CALL.body
```
  
#### `property` node type

Get and set {{site.base_gateway}} host properties.

Whether a **get** or **set** operation is performed depends upon the node inputs:

* If an input port is configured, **set** the property
* If no input port is configured, **get** the property and map it to the output
    port

##### Input ports

* `value`: set the property to the value from this port

##### Output ports

* `value`: the property value that was retrieved

##### Supported attributes

* `property` (**required**): the name of the property
* `content_type`: the MIME type of the property (example: `application/json`)
    * **get**: controls how the value is _decoded_ after reading it.
    * **set**: controls how the value is _encoded_ before writing it. This is
        usually does not need to be specified, as DataKit can typically infer
        the correct encoding from the input type.

##### Examples

Get the current value of `my.property`:

```yaml
- name: get_property
  type: property
  property: my.property
```

Set the value of `my.property` from `some_other_node.port`:

```yaml
- name: set_property
  type: property
  property: my.property
  input: some_other_node.port
```

Get the value of `my.json-encoded.property` and decode it as JSON:

```yaml
- name: get_json_property
  type: property
  property: my.json-encoded.property
  content_type: application/json
```

### Implicit nodes

DataKit defines a number of implicit nodes that can be used without being
explicitly declared. These reserved node names cannot be used for user-defined
nodes. These are:

<!--vale off-->
{% table %}
columns:
  - title: Node
    key: node
  - title: Input ports
    key: input_ports
  - title: Output ports
    key: output_ports
  - title: Description
    key: description
rows:
  - node: request
    input_ports: none
    output_ports: "`body`, `headers`, `query`"
    description: The incoming request
  - node: "`service_request`"
    input_ports: "`body`, `headers`, `query`"
    output_ports: none
    description: Request sent to the service being proxied to
  - node: "`service_response`"
    input_ports: none
    output_ports: "`body`, `headers`"
    description: Response sent by the service being proxied to
  - node: "`response`"
    input_ports: "`body`, `headers`"
    output_ports: none
    description: Response to be sent to the incoming request
{% endtable %}
<!--vale off-->

The `headers` ports produce and consume maps from header names to their values.
Keys are header names are normalized to lowercase.
Values are strings if there is a single instance of a header,
or arrays of strings if there are multiple instances of the same header.

The `query` ports produce and consume maps with key-value pairs representing
decoded URL query strings. If the value in the pair is JSON null,
the key is encoded without a value (to encode `key=null`, use `"null"`
as a value).

The `body` output ports produce either raw strings or JSON objects,
depending on their corresponding `Content-Type` values.

Likewise, the `body` input ports accept either raw strings or JSON objects,
and both their `Content-Type` and `Content-Length` are automatically adjusted,
according to the type and size of the incoming data.

## Debugging

DataKit includes support for debugging your configuration.

### Execution tracing

By setting the `X-DataKit-Debug-Trace` header, DataKit records the execution
flow and the values of intermediate nodes, reporting the output in the request
body in JSON format.

If the debug header value is set to `0`, `false`, or `off`, this is equivalent to
unsetting the debug header: tracing will not happen and execution will run
as normal. Any other value will enable debug tracing.

## Datakit example configurations

Example configuration by use case.

### Authenticate {{site.base_gateway}} to a third-party service

```yaml
plugins:
- name: datakit
  service: my-service
  config:
    debug: true
    nodes:
    - name: BUILD_AUTH_HEADERS
      jq: |
        {
            "Authorization": "Basic YGA8NNu8877lkOmNsagsdWAyZXQ=",   
        }
      type: jq
    - name: BUILD_AUTH_BODY
      type: handlebars
      template: |
          grant_type=client_credentials
    - name: AUTH_CALL
      type: call
      inputs:
      - headers: BUILD_AUTH_HEADERS
      - body: BUILD_AUTH_BODY
      url:  http://auth-server:5000/token
      method: post
    - name: BUILD_UPSTREAM_AUTH_HEADERS
      type: jq
      inputs:
      - auth: AUTH_CALL
      output:
        service_request.headers
      jq: |
        {
        "Authorization":$auth.token_type + " " +    $auth.access_token
        }
```

### Manipulate request headers

```yaml
plugins:
- name: datakit
  service: my-service
  config:
    debug: true
    nodes:
    - name: MY_HEADERS
      type: jq
      inputs:
      - req: request.headers
      jq: |
        {
          "X-My-Call-Header": $req.apikey // "default value"
        }
    - name: CALL
      type: call
      inputs:
      - headers: MY_HEADERS
      url: https://httpbin.konghq.com/anything
    - name: EXIT
      type: exit
      inputs:
      - body: CALL.body
      status: 200
```

### Combine two APIs into one response

```yaml
plugins:
- name: datakit
  service: my-service
  config:
    debug: true
    nodes:
    - name: CAT_FACT
      type: call
      url:  https://catfact.ninja/fact
    - name: DOG_FACT
      type: call
      url:  https://dogapi.dog/api/v1/facts
    - name: JOIN
      type: jq
      inputs:
      - cat: CAT_FACT.body
      - dog: DOG_FACT.body
      jq: |
        {
          "cat_fact": $cat.fact,
          "dog_fact": $dog.facts[0]
        }
    - name: EXIT
      type: exit
      inputs:
      - body: JOIN
      status: 200
```

### Pass API response data into templates using handlebars

```yaml
services:
- name: demo
  url: http://httpbin.konghq.com
  routes:
  - name: my-route
    paths:
    - /anything
    strip_path: false
    methods:
    - GET
    - POST
    plugins:
    - name: datakit
      config:
        debug: true
        nodes:
        - name: FIRST
          type: call
          url: https://api.zippopotam.us/br/93000-000
        - name: MY_HEADERS
          type: jq
          inputs:
          - first: FIRST.body
          output: service_request.headers
          jq: |
            {
              "X-Hello": "World",
              "X-Foo": "Bar",
              "X-Country": $first.country
            }
        - name: MY_BODY
          type: handlebars
          content_type: text/plain
          inputs:
          - first: FIRST.body
          output: service_request.body
          template: |
            {% raw %} Coordinates for {{ first.places.0.[place name] }}, {{ first.places.0.state }}, {{ first.country }} are ({{ first.places.0.latitude }}, {{ first.places.0.longitude }}){% endraw %}.
```

### Adjust {{site.base_gateway}} Service and Route properties

```yaml
services:
- name: demo
  url: http://httpbin.konghq.com
  routes:
  - name: my-route
    paths:
    - /anything
    strip_path: false
    methods:
    - GET
    - POST
    plugins:
    - name: post-function
      config:
        access:
        - |
          local cjson = require("cjson")

          kong.ctx.shared.from_lua = cjson.encode({
            nested = {
              message = "hello from lua land!",
            },
          })
        header_filter:
        - |
          local cjson = require("cjson")
          local ctx = kong.ctx.shared

          local api_response = ctx.api_response or "null"
          local res = cjson.decode(api_response)

          kong.response.set_header("X-Lua-Encoded-Object", api_response)
          kong.response.set_header("X-Lua-Plugin-Country", res.country)
          kong.response.set_header("X-Lua-Plugin-My-String", ctx.my_string)
          kong.response.set_header("X-Lua-Plugin-My-Encoded-String", ctx.my_encoded_string)
    - name: datakit
      config:
        debug: true
        nodes:
        #
        # read "built-in" kong properties
        #
        - name: ROUTE_ID
          type: property
          property: kong.route_id

        - name: SERVICE
          type: property
          property: kong.router.service
          content_type: application/json

        #
        # access values from ctx
        #
        - name: LUA_VALUE_ENCODED
          type: property
          property: kong.ctx.shared.from_lua

        - name: LUA_VALUE_DECODED
          type: property
          property: kong.ctx.shared.from_lua
          content_type: application/json

        #
        # make an external API call and stash the result in kong.ctx.shared
        #
        - name: API
          type: call
          url: https://api.zippopotam.us/br/93000-000

        - name: SET_API_RESPONSE
          type: property
          property: kong.ctx.shared.api_response
          input: API.body

        #
        # fetch a property that we know does not exist
        #
        - name: UNSET_PROP
          type: property
          # should return `null`
          property: kong.ctx.shared.nothing_here

        #
        # emit a JSON-encoded string from jq and store it in kong.ctx.shared
        #
        - name: JSON_ENCODED_STRING
          type: jq
          jq: '"my string"'

        # encode as `my string`
        - name: SET_MY_STRING_PLAIN
          type: property
          input: JSON_ENCODED_STRING
          property: kong.ctx.shared.my_string

        # [JSON-]encode as `"my string"`
        - name: SET_MY_STRING_ENCODED
          type: property
          input: JSON_ENCODED_STRING
          property: kong.ctx.shared.my_encoded_string
          content_type: application/json

        # get `my string`, return `my string`
        - name: GET_PLAIN_STRING
          type: property
          property: kong.ctx.shared.my_string

        # get `"my string"`, return `"my string"`
        - name: GET_JSON_STRING_ENCODED
          type: property
          property: kong.ctx.shared.my_encoded_string

        # get `"my string"`, decode, return `my string`
        - name: GET_JSON_STRING_DECODED
          type: property
          property: kong.ctx.shared.my_encoded_string
          content_type: application/json

        #
        # assemble a response
        #
        - name: BODY
          type: jq
          inputs:
            # value is also fetched after being set
            API_body: API.body
            SERVICE: SERVICE
            ROUTE_ID: ROUTE_ID
            LUA_VALUE_ENCODED: LUA_VALUE_ENCODED
            LUA_VALUE_DECODED: LUA_VALUE_DECODED
            UNSET_PROP: UNSET_PROP
            GET_PLAIN_STRING: GET_PLAIN_STRING
            GET_JSON_STRING_ENCODED: GET_JSON_STRING_ENCODED
            GET_JSON_STRING_DECODED: GET_JSON_STRING_DECODED
          jq: |
            {
              "API.body": $API_body,
              SERVICE: $SERVICE,
              ROUTE_ID: $ROUTE_ID,
              LUA_VALUE_ENCODED: $LUA_VALUE_ENCODED,
              LUA_VALUE_DECODED: $LUA_VALUE_DECODED,
              UNSET_PROP: $UNSET_PROP,
              GET_PLAIN_STRING: $GET_PLAIN_STRING,
              GET_JSON_STRING_ENCODED: $GET_JSON_STRING_ENCODED,
              GET_JSON_STRING_DECODED: $GET_JSON_STRING_DECODED,
            }

        - name: exit
          type: exit
          inputs:
            body: BODY
```