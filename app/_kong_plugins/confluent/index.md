---
title: 'Confluent'
name: 'Confluent'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Transform requests into Kafka messages in a Confluent Kafka topic.'

tags:
  - kafka
  - data-streaming
  - confluent
  - transformations

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: confluent.png

categories:
  - transformations

related_resources:
  - text: Kafka Log
    url: /plugins/kafka-log/
  - text: Kafka Upstream
    url: /plugins/kafka-upstream/

search_aliases:
  - kafka
  - protocol mediation

premium_partner: true
---

With Kafka at its core, [Confluent](https://confluent.io) offers complete, fully managed, cloud-native data streaming that's available everywhere your data and applications reside. Using the Confluent plugin, you can send HTTP request data to Apache Kafka by constructing Kafka messages from incoming {{site.base_gateway}} HTTP requests.

{{site.base_gateway}} also provides Kafka Log and Kafka Upstream plugins for publishing logs and messages to an Apache Kafka [topic](https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/index.html):

* See [Kafka Log](/plugins/kafka-log/)
* See [Kafka Upstream](/plugins/kafka-upstream/)

{:.info} 
> **Note**: This plugin has the following known limitations:
> * Message compression is not supported.
> * The message format is not customizable.
> * {{site.base_gateway}} supports Kafka 4.0 starting from version 3.10.

## Schema registry support {% new_in 3.11 %}

{% include_cached /plugins/confluent-kafka-consume/schema-registry.md name=page.name slug=page.slug workflow='producer' %}

## Kafka record headers {% new_in 3.15 %}

The Confluent plugin can forward HTTP request headers as [Kafka record headers](https://kafka.apache.org/documentation/#recordheader), which are per-record key/value metadata that lives alongside the message key and value.
This lets consumers read routing, tracing, or tenancy context without parsing the message payload.

Configure the [`config.headers`](/plugins/confluent/reference/#schema--config-headers) block to control which headers are forwarded:

{% table %}
columns:
  - title: Mode
    key: mode
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - mode: "Allowlist ([`forward_all_by_default: false`](/plugins/confluent/reference/#schema--config-headers-forward-all-by-default))"
    description: "Only forward headers listed in [`include_headers`](/plugins/confluent/reference/#schema--config-headers-include-headers)."
    example: "[Forward HTTP headers as Kafka record headers (allowlist mode)](/plugins/confluent/examples/record-headers-allowlist/)"
  - mode: "Blocklist ([`forward_all_by_default: true`](/plugins/confluent/reference/#schema--config-headers-forward-all-by-default))"
    description: "Forward all headers except those listed in [`exclude_headers`](/plugins/confluent/reference/#schema--config-headers-exclude-headers)."
    example: "[Forward HTTP headers as Kafka record headers (blocklist mode)](/plugins/confluent/examples/record-headers-blocklist/)"
{% endtable %}

Use [`config.headers.name_mappings`](/plugins/confluent/reference/#schema--config-headers-name-mappings) to rename an HTTP header to a different Kafka record header key.

Use [`config.headers.repeated_headers_behavior`](/plugins/confluent/reference/#schema--config-headers-repeated-headers-behavior) to control how duplicate HTTP headers are handled: `retain_duplicates` (default) creates a separate record header per value, `take_first` uses only the first value, and `concatenate_by_comma` joins all values with a comma.

{:.info}
> **Note**: The [`config.forward_headers`](/plugins/confluent/reference/#schema--config-forward-headers) setting embeds request headers inside the message body. `config.headers` is a separate configuration block that sets native Kafka record headers on the produced record.