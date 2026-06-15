---
title: Using Debugger for Datakit
description: 'Use {{site.konnect_short_name}} Debugger to inspect Datakit node execution: trace node spans, view I/O values per node lifecycle event, and understand how sanitization rules apply to Datakit tracing data.'
breadcrumbs:
  - /observability/
  - /observability/debugger/
content_type: reference
layout: reference
search_aliases:
  - active tracing
  - debugger
products:
    - observability
    - konnect
    - gateway
works_on:
    - konnect
tags:
  - tracing
  - debugger

related_resources:
  - text: "{{site.konnect_short_name}} Debugger"
    url: /observability/debugger/
  - text: Datakit plugin
    url: /plugins/datakit/
  - text: Datakit in {{site.base_gateway}}
    url: /gateway/datakit/

min_version:
  gateway: '3.15'
---

When you run a [Debugger session](/observability/debugger/) on a {{site.base_gateway}} instance that uses the [Datakit plugin](/plugins/datakit/), Debugger captures tracing data for each Datakit node in the pipeline.
This gives you visibility into how data flows through your Datakit configuration.
You can see which nodes ran, what values they received and produced, and where errors or skips occurred.

Datakit tracing provides debugging detail without exposing sensitive data.
{{site.base_gateway}} tracks values as they move through the Datakit workflow and applies redaction and sanitization rules before sending trace data to {{site.konnect_short_name}}.

## Enable tracing event collection

To collect Datakit tracing events, start a {{site.konnect_short_name}} Debugger session with body payload capture.
If header-only payload capture is enabled, node spans will be recorded but tracing events won't be uploaded.

## Datakit node spans

For each Datakit node that executes, Debugger creates a span named `kong.datakit.node.NODE_NAME`, where `NODE_NAME` is the name you assigned to the node in your Datakit configuration.

Node spans capture metadata about node execution but don't contain node input or output values.
Values are only captured in the separate Datakit tracing event payload.

If a node is skipped due to branch routing rules, it normally won't create a span because execution hasn't started.
Information about skipped nodes is available in Datakit tracing events.

Each span includes the following attributes:

<!--vale off-->
{% table %}
columns:
  - title: Attribute
    key: attribute
  - title: Description
    key: description
  - title: Values
    key: values
rows:
  - attribute: "`proxy.kong.datakit.node.type`"
    description: The type of the Datakit node.
    values: |
      Depends on the node, for example, `jq`, `call`, or `jwt_decode`. 
      See the [Datakit nodes reference](/plugins/datakit/#node-types) for all supported node types.
  - attribute: "`proxy.kong.datakit.node.status`"
    description: The final status of the node after execution.
    values: "`complete`, `fail`, or `cancel`"
{% endtable %}
<!--vale on-->

## Tracing events

Tracing events capture the full lifecycle of each node, including input and output values.
Each event corresponds to a specific point in a node's execution and includes the data the node was working with at that point.

{:.info}
> **Note**: Large values may be omitted from tracing events if they exceed the capture size limit.

Each tracing event includes the following fields:

<!--vale off-->
{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`name`"
    description: The name of the Datakit node.
  - field: "`type`"
    description: |
      The type of the Datakit node (for example, `jq`, `call`, `jwt_decode`).
  - field: "`action`"
    description: |
      The lifecycle action that generated this event. See [Actions](#actions).
  - field: "`timestamp`"
    description: The time the event occurred.
  - field: "`value`"
    description: |
      The input or output value associated with this action.
      <br><br>
      The `run` action maps to input values, while the `complete`, `fail`, `cancel` actions map to output values.
  - field: "`error`"
    description: |
      The error message, if the action is `fail`.
{% endtable %}
<!--vale on-->

### Actions

The `action` field describes what happened to the node at the moment the event was recorded.

<!--vale off-->
{% table %}
columns:
  - title: Action
    key: action
  - title: Value captured
    key: value
  - title: Description
    key: description
rows:
  - action: "`run`"
    value: Input value
    description: The node started running. The event includes the input value the node received.
  - action: "`complete`"
    value: Output value
    description: The node finished successfully. The event includes the output value the node produced.
  - action: "`fail`"
    value: "Partial output value (if any)"
    description: The node encountered an error. The event includes an error message and any partial output.
  - action: "`skip`"
    value: Routing value
    description: The node was skipped due to branch routing. The event shows the routing value that caused the skip.
  - action: "`cancel`"
    value: None
    description: The node was canceled before it completed.
  - action: "`schedule`"
    value: Input value
    description: "`call` nodes only. The node was scheduled for an async HTTP request."
  - action: "`dispatch`"
    value: Request data
    description: "`call` nodes only. The async HTTP request was dispatched."
  - action: "`resume`"
    value: Response data
    description: "`call` nodes only. The async HTTP response was received and the node resumed execution."
{% endtable %}
<!--vale on-->

## Redaction and sanitization

Datakit values can carry arbitrary content, including Vault secrets, authentication headers, personally identifiable information (PII), response bodies, and transformed values.
Datakit applies redaction and sanitization rules based on the source of the node's input.
Tracing values are sanitized on the data plane before being transmitted to {{site.konnect_short_name}}.

The same [custom masking rules](/observability/debugger/#payload-collection-and-sanitization) you configure for general Debugger payload capture also apply to Datakit tracing events.

### Vault-derived values

Any value that comes from a Vault secret is always replaced with `********`, regardless of other sanitization rules.
If a node's output is derived from a Vault-resolved value, the entire output is redacted.

### Header sanitization

When a Datakit value is a headers map (a structured map of header name-value pairs), it's sanitized using header-name rules.
The following headers are masked by default:

* `authorization`
* `api-key`
* `x-api-key`
* `x-consumer-username`
* `x-consumer-custom-id`
* `x-consumer-id`
* `x-credential-identifier`

Header context is lost when a value passes through a transformation node like `jq`, `json_to_xml`, or `xml_to_json`.
After transformation, the value no longer carries header context and is sanitized using body rules instead.

### Body and structured value sanitization

String values are sanitized using body rules (regex or JSONPath).
Structured values (maps and objects) are sanitized using body rules with JSONPath expressions applied to the structure.
When a node's output is assembled from individual field-level inputs, each field is sanitized independently according to the rules that apply to its source.

### Node-specific sanitization behavior

The sanitization applied to a node's tracing event values depends on the node type and the source of its inputs. In summary:
* Values that come from request data use sanitizer rules configured for request data.
* Values that come from response data use sanitizer rules configured for response data.
* Values that combine request and response data can use both request and response sanitizer rules.

The following table breaks down sanitization behavior by node:

<!--vale off-->
{% table %}
columns:
  - title: Node type
    key: node
  - title: Input or output
    key: io
  - title: Sanitization applied
    key: sanitization
rows:
  - node: "`request`"
    io: Headers
    sanitization: Header-name rules
  - node: "`request`"
    io: Body, query parameters
    sanitization: Body rules
  - node: "`response`"
    io: All values
    sanitization: Based on connected inputs
  - node: "`service_request`"
    io: All values
    sanitization: Based on connected inputs
  - node: "`service_response`"
    io: All values
    sanitization: Based on connected inputs
  - node: "`vault`"
    io: Output
    sanitization: "Always `********` (vault-derived)"
  - node: "`call`"
    io: Output headers
    sanitization: Response header-name rules
  - node: "`call`"
    io: Output body
    sanitization: Response body rules
  - node: "`static`"
    io: Output
    sanitization: Only if the value matches a configured rule
  - node: "`property GET`"
    io: Output
    sanitization: Only if the value matches a configured rule
  - node: "`property SET`"
    io: Output
    sanitization: Based on input values
  - node: "`jq`"
    io: Output
    sanitization: "Body rules (header context lost after transformation)"
  - node: "`json_to_xml`"
    io: Output
    sanitization: "Body rules (header context lost after transformation)"
  - node: "`xml_to_json`"
    io: Output
    sanitization: "Body rules (header context lost after transformation)"
  - node: "`jwt_decode`"
    io: Input JWT
    sanitization: Always redacted
  - node: "`jwt_decode`"
    io: JWT signature
    sanitization: Always redacted
  - node: "`jwt_decode`"
    io: JWT header and payload claims
    sanitization: Body rules
  - node: "`jwt_verify`"
    io: Input token and key
    sanitization: Always redacted
  - node: "`jwt_verify`"
    io: Output claims and header
    sanitization: Body rules
  - node: "`jwt_sign`"
    io: Input key
    sanitization: Always redacted
  - node: "`jwt_sign`"
    io: Output token
    sanitization: Always redacted
  - node: "`jwt_sign`"
    io: Input claims and headers
    sanitization: Body rules
  - node: "`cache GET`"
    io: Output
    sanitization: Only if the value matches a configured rule
  - node: "`cache SET`"
    io: Cached data
    sanitization: Based on input data source
  - node: "`cache SET`"
    io: Generated values
    sanitization: Body rules
  - node: "`branch`"
    io: Routing values
    sanitization: Body rules
  - node: "`exit`"
    io: Response body
    sanitization: Based on input sources
  - node: "`exit`"
    io: Response headers
    sanitization: Based on input sources
{% endtable %}
<!--vale on-->

## Custom sanitization rules

Custom payload sanitization rules configured for Debugger also apply to Datakit tracing values.
Custom body rules can use regex or JSONPath expressions ([RFC 9535](https://www.rfc-editor.org/rfc/rfc9535)).

For object inputs and outputs, each field is sanitized independently.
When a node's output is assembled from field-level inputs (for example, `request.headers` connected to `jq.headers`), Datakit preserves per-field sanitization for that output.
Transformed `$self` outputs, like the full output of a `jq` node, are sanitized as a single value.

Write JSONPath rules relative to the value as it appears in the tracing event.
For example, `jwt_decode` output is an object with `header`, `payload`, and `signature` fields:

```json
{
  "header": {
    "typ": "JWT",
    "alg": "HS256"
  },
  "payload": {
    "sub": "user-123",
    "email": "alice@example.com"
  },
  "signature": "..."
}
```

* To redact `payload.sub`, use `$.payload.sub`.
* To redact `header.typ`, use `$.header.typ`.

If the `jwt_decode` output is then passed through a `jq` node that reshapes it, write your JSONPath rule relative to the `jq` output structure instead.

To redact any field named `sub` regardless of its position in the structure, use the resursive deep-scan JSONPath rule `$..sub`.