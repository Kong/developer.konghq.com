---
title: "{{site.event_gateway}} known limitations"
content_type: reference
layout: reference

description: This page lists the current {{site.event_gateway}} limitations.
  
related_resources:
  - text: "{{site.event_gateway}}"
    url: /event-gateway/
  - text: "Upgrading {{site.event_gateway_short}}"
    url: /event-gateway/upgrade/
  - text: "{{site.event_gateway_short}} breaking changes and known issues"
    url: /event-gateway/breaking-changes/
  - text: "{{site.event_gateway_short}} version support"
    url: /event-gateway/version-support-policy/
  - text: "{{site.event_gateway_short}} changelog"
    url: /event-gateway/changelog/
  - text: "Verify {{site.event_gateway_short}} image signatures and attestations"
    url: /event-gateway/verify-image-signatures-and-attestations/

products:
    - event-gateway

breadcrumbs:
  - /event-gateway/
---

{{site.event_gateway}} currently has the following limitations:

## Unsupported features

* [Queues for Kafka](https://cwiki.apache.org/confluence/display/KAFKA/KIP-932%3A+Queues+for+Kafka) are not supported
* The new [consumer rebalance protocol](https://cwiki.apache.org/confluence/display/KAFKA/KIP-848%3A+The+Next+Generation+of+the+Consumer+Rebalance+Protocol) is not supported
* [Client metrics and observability for clients](https://cwiki.apache.org/confluence/display/KAFKA/KIP-714%3A+Client+metrics+and+observability) is not supported (you may need to set `enable.metrics.push=false` on recent java clients).
* SASL Handshake v0 is not supported as it is being removed in Kafka 4.0 (see [Kafka Improvement Proposal 896](https://cwiki.apache.org/confluence/x/K5sODg)).

## Untested features

* [Compacted topics](https://docs.confluent.io/kafka/design/log_compaction.html#topic-compaction) used with policies and namespaces are untested

## Record headers

Kafka record headers are multi-valued: the [Kafka protocol](https://cwiki.apache.org/confluence/display/KAFKA/KIP-82+-+Add+Record+Headers) allows the same header key to appear more than once in a single record, and clients can read every occurrence.

{{site.event_gateway_short}} models record headers as a single value per key. 
When a record is processed by a policy that reads or transforms headers (for example, Encryption, Schema Validation, or Modify Headers policies), records that carry duplicate header keys are collapsed so that only the **last** value for each key is kept. 
Earlier values with the same key are dropped.

This only affects records that {{site.event_gateway_short}} decodes to apply record-level policies. 
If your clients rely on multiple headers that share the same key, don't route those topics through header-transforming policies.

See the [{{site.event_gateway}} headers reference](/event-gateway/headers/) for the headers {{site.event_gateway_short}} adds and interprets.


