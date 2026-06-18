---
title: 'Kafka Upstream'
name: 'Kafka Upstream'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Transform requests into Kafka messages in a Kafka topic.'


products:
    - gateway

works_on:
    - on-prem
    - konnect

tags:
  - traffic-control
  - events
  - kafka

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: kafka-upstream.png

categories:
  - transformations

search_aliases:
  - kafka-upstream
  - events
  - protocol mediation

min_version:
  gateway: '1.3'
---

This plugin converts requests into [Apache Kafka](https://kafka.apache.org/) messages and publishes them to a specified Kafka topic.  
For more details, see [Kafka topics](https://kafka.apache.org/documentation/#intro_concepts_and_terms).

{{site.base_gateway}} also offers a separate [Kafka Log](/plugins/kafka-log/) plugin for streaming logs to Kafka topics.

## Implementation details

This plugin uses the [lua-resty-kafka](https://github.com/kong/lua-resty-kafka) client.

When encoding request bodies, several things happen:

* For requests with a content-type header of `application/x-www-form-urlencoded`, `multipart/form-data`,
  or `application/json`, this plugin passes the raw request body in the `body` attribute, and tries
  to return a parsed version of those arguments in `body_args`. If this parsing fails, an error message is
  returned and the message is not sent.
* If the `content-type` is not `text/plain`, `text/html`, `application/xml`, `text/xml`, or `application/soap+xml`,
  then the body will be base64-encoded to ensure that the message can be sent as JSON. In such a case,
  the message has an extra attribute called `body_base64` set to `true`.

## Schema registry support {% new_in 3.11 %}

{% include_cached /plugins/confluent-kafka-consume/schema-registry.md name=page.name slug=page.slug workflow='producer' %}

## Kafka record headers {% new_in 3.15 %}

The Kafka Upstream plugin can forward HTTP request headers as [Kafka record headers](https://kafka.apache.org/documentation/#recordheader), which are per-record key/value metadata that lives alongside the message key and value.
This lets consumers read routing, tracing, or tenancy context without parsing the message payload.

Configure the [`config.headers`](/plugins/kafka-upstream/reference/#schema--config-headers) block to control forwarding headers:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - mode: "Allowlist ([`forward_all_by_default: false`](/plugins/kafka-upstream/reference/#schema--config-headers-forward-all-by-default))"
    description: "Only forward headers listed in [`include_headers`](/plugins/kafka-upstream/reference/#schema--config-headers-include-headers)."
    example: "[Forward HTTP headers as Kafka record headers (allowlist mode)](/plugins/kafka-upstream/examples/record-headers-allowlist/)"
  - mode: "Blocklist ([`forward_all_by_default: true`](/plugins/kafka-upstream/reference/#schema--config-headers-forward-all-by-default))"
    description: "Forward all headers except those listed in [`exclude_headers`](/plugins/kafka-upstream/reference/#schema--config-headers-exclude-headers)."
    example: "[Forward HTTP headers as Kafka record headers (blocklist mode)](/plugins/kafka-upstream/examples/record-headers-blocklist/)"
{% endtable %}

Use [`config.headers.name_mappings`](/plugins/kafka-upstream/reference/#schema--config-headers-name-mappings) to rename an HTTP header to a different Kafka record header key.

Use [`config.headers.repeated_headers_behavior`](/plugins/kafka-upstream/reference/#schema--config-headers-repeated-headers-behavior) to control how duplicate HTTP headers are handled: `retain_duplicates` (default) creates a separate record header per value, `take_first` uses only the first value, and `concatenate_by_comma` joins all values with a comma.

{:.info}
> **Note**: The [`config.forward_headers`](/plugins/kafka-upstream/reference/#schema--config-forward-headers) setting embeds request headers inside the message body. `config.headers` is a separate configuration block that sets native Kafka record headers on the produced record.


## Known issues and limitations

Known limitations:

1. Message compression is not supported.
1. In {{site.base_gateway}} 3.9 or earlier, the message format is not customizable.
