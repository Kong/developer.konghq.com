---
title: 'Correlation ID'
name: 'Correlation ID'

content_type: plugin

publisher: kong-inc
description: 'Correlate requests and responses using a unique ID'


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
icon: correlation-id.png

categories:
  - transformations

search_aliases:
  - correlation-id

related_resources:
  - text: Add Correlation IDs to {{site.base_gateway}} logs
    url: /how-to/add-correlation-ids-to-gateway-logs/

faqs:
  - q: Can I see my correlation IDs in my {{site.base_gateway}} logs?
    a: |
      Yes, if you edit your Nginx logging parameters you can see your correlation ID in the Nginx access log. For complete instructions, see [Add Correlation IDs to {{site.base_gateway}} logs](/how-to/add-correlation-ids-to-gateway-logs/).

min_version:
  gateway: '1.0'
---

The Correlation ID plugin lets you correlate requests and responses using a unique ID transmitted as HTTP headers.

## How it works

When you enable this plugin, it adds a new header to all of the requests processed by {{site.base_gateway}}. This header contains the name configured in the `config.header_name` variable, and a unique value is generated according to `config.generator`.

This header is always added in calls to your upstream services, and optionally echoed back to your clients according to the `config.echo_downstream` setting.

If a header with the same name is already present in the client request, the plugin honors it and does **not** tamper with it.

## Generators

Correlation ID uses a generator (`config.generator`) to create different headers for requests processed by {{site.base_gateway}}.

### uuid

Format:
```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

This format generates a hexadecimal UUID for each request.

### uuid#counter

Format:
```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx#counter
```

This format generates a single UUID on a per-worker basis, and the requests append a counter to the UUID after a `#` character. The `counter` value starts at `0` for each worker, and gets incremented independently of the others.

This format provides better performance, but might be harder to store or process for analyzing (due to its format and low cardinality).

### tracker

Format:
```
ip-port-pid-connection-connection_requests-timestamp
```

This correlation ID contains more practical implications for each request.

The following is a detailed description of the field:

{% table %}
columns:
  - title: Form parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: "`ip`"
    description: Address of the server that accepts a request.
  - parameter: "`port`"
    description: Port of the server that accepts a request.
  - parameter: "`pid`"
    description: Process ID of the Nginx worker process.
  - parameter: "`connection`"
    description: Connection serial number.
  - parameter: "`connection_requests`"
    description: Current number of requests made through a connection.
  - parameter: "`timestamp`"
    description: A floating-point number for the elapsed time in seconds (including milliseconds as the decimal part) from the epoch for the current timestamp from the Nginx cached time.
{% endtable %}

## File Log plugin

When this plugin is used together with the [File Log](/plugins/file-log/) plugin, the `correlation_id` field is added to the JSON log object. 
