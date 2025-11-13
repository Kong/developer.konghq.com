---
title: "{{site.event_gateway}} known limitations"
content_type: reference
layout: reference

description: This page lists the current {{site.event_gateway}} limitations.
  
related_resources:
  - text: "{{site.event_gateway}}"
    url: /event-gateway/

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

## Untested features

* [Compacted topics](https://docs.confluent.io/kafka/design/log_compaction.html#topic-compaction) used with policies and namespaces are untested


