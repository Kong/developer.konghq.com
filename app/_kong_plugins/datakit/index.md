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

{:.warning}
> Prior to {{site.base_gateway}} 3.11, the Datakit plugin was not available in {{site.base_gateway}} packages by default. 
If you are running {{site.base_gateway}} 3.9 or 3.10, enable the plugin in one of the following ways:
> * **Package install:** Set `wasm=on` in [`kong.conf`](/gateway/configuration/#wasm-section) before starting {{site.base_gateway}}
> * **Docker:** Set `export WASM=on` in the environment
> * **Kubernetes:** Set `WASM=on` using the [Custom Plugin](/kubernetes-ingress-controller/custom-plugins/) instructions

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
  - usecase: "[Internal authentication](/plugins/datakit/examples/authenticate-third-party/)"
    description: Use internal auth within your ecosystem by sending response headers to upstreams.
  - usecase: "[Service callout](/plugins/datakit/examples/combine-two-apis-into-one-response/)"
    description: Reach out to a third-party service, then combine with other requests or augment the original request before sending back to the upstream.
  - usecase: "[Dynamic service discovery](/plugins/datakit/examples/manipulate-request-headers/)"
    description: Integrate seamlessly with third-party APIs that assist with service discovery and set new upstream values dynamically.
  - usecase: "[Get and set Kong entity properties](/how-to/)"
    description: |
      Use Datakit to adjust {{site.base_gateway}} entity configurations. For example, you could replace the service URL or set a header on a route.{% endtable %}
<!--vale on-->

## How does the Datakit plugin work?

The core component of Datakit is a node. Nodes are inputs to other nodes, which creates the execution path for a given Datakit configuration. 


Datakit provides the following node types:
* `call`: Third-party HTTP calls
* `jq`: Transform data and cast variables with `jq` to be shared with other nodes
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

### Node ports

Datakit nodes can have input ports and output ports. Input ports consume data, and output ports produce data.

You can link one node's output port to another node's input port.
An input port can receive at most one link, that is, data can only arrive
into an input via one other node. Therefore, there are no race conditions.

An output port can be linked to multiple nodes. Therefore, one node can provide data to several other nodes.

A node only triggers when data is available to all its connected input ports, only when all nodes connected to its inputs have finished executing. Each node triggers only once.

### Implicit nodes

Datakit defines a number of implicit nodes that can be used without being explicitly declared. These reserved node names can't be used for user-defined nodes. 
They include:

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

Datakit includes support for debugging your configuration using execution tracing.

By setting the `X-DataKit-Debug-Trace` header, Datakit records the execution flow and the values of intermediate nodes, 
reporting the output in the request body in JSON format.

If the debug header value is set to `0`, `false`, or `off`, this is equivalent to unsetting the debug header. 
In this case, tracing won't happen and execution will run as normal. 
Any other value will enable debug tracing.