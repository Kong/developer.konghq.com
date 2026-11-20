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

{% include_cached /plugins/confluent-kafka-consume/record-headers.md name=page.name %}

## Message compression {% new_in 3.16 %}

{% include_cached /plugins/confluent-kafka-consume/compression.md name=page.name %}

For an example, see [Compress messages before sending to Kafka](/plugins/kafka-upstream/examples/compress-messages/).

## Debugging {% new_in 3.15 %}

By default, when producing a message fails, the plugin returns a generic error to the HTTP client and logs the real cause in the {{site.base_gateway}} logs:

```json
{"message": "Bad Gateway", "error": "could not send message to topic"}
```

To include the detailed Kafka client error in the response instead, set [`config.error_handling.return_error_message`](/plugins/kafka-upstream/reference/#schema--config-error-handling-return-error-message) to `true` (`false` by default).
This lets you see the exact broker rejection (for example, `TopicAuthorizationFailed`) without checking the {{site.base_gateway}} logs.

{:.warning}
> **Warning**: Do not enable this in production.
> The detailed error may expose internal details like topic names and ACL denials.

## Delivery guarantees {% new_in 3.18 %}

By default, the plugin delivers each message at least once. A retried request can create duplicate messages.

Two settings strengthen delivery:

* `producer_idempotence`: the broker stores a retried batch only once, so a retry does not create duplicates.
* `producer_transactions`: the plugin sends all messages of one request in a single Kafka transaction. The messages for all target topics commit together, or not at all.

Both settings need synchronous delivery. Set `producer_async` to `false` and `producer_request_acks` to `-1`. Transactions also need `producer_idempotence`.

The plugin builds the transactional ID as `<prefix>.<node ID>.<worker ID>`. The default prefix is `kong-<cluster_name>-<config hash>`, so each worker and each plugin config uses a distinct producer. A restarted worker reuses its ID and fences its previous producer, so the broker can abort an unfinished transaction.

Set `transactional_id_prefix` to match a Kafka `TransactionalId` ACL. If several transaction-enabled configs share a `cluster_name` and target the same brokers and topic, give each config a distinct `transactional_id_prefix`. Otherwise their producers fence each other.

{:.warning}
> **Consumers must set `isolation.level=read_committed`.** With the default `read_uncommitted` isolation level, a consumer also reads messages from aborted transactions.

{:.warning}
> **Do not retry a `502` response blindly.** A `200` response means the broker committed the transaction. A `502` response means the commit outcome is unknown. Use an application-level idempotency key when you retry.

Transactions add a coordinator lookup, one `AddPartitionsToTxn` request for each new partition, and one `EndTxn` request to each call. The plugin serializes transactions per worker. Expect lower throughput than the default asynchronous mode.

### Kafka prerequisites

* Apache Kafka 0.11 or later.
* Configure `transaction.state.log.replication.factor` and `transaction.state.log.min.isr` for the cluster.
* Grant `IdempotentWrite` on the cluster and `Write` on the `TransactionalId` resource. See [Kafka authorization](https://kafka.apache.org/documentation/#security_authz).

## Known issues and limitations

Known limitations:

1. In {{site.base_gateway}} 3.9 or earlier, the message format is not customizable.

## Authentication

{% include_cached /plugins/kafka/auth.md slug=page.slug name=page.name %}
