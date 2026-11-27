---
title: "{{site.webhook_engine}} architecture"
content_type: reference
layout: reference

description: |
  How {{ site.webhook_engine }} works: the event flow from publisher through listener, channel, and Postgres event store to subscriber endpoints, and the entities behind it.
related_resources:
  - text: "{{site.webhook_engine}}"
    url: /webhook-engine/

products:
    - webhook-engine

breadcrumbs:
  - /webhook-engine/

tools:
  - konnect-api

works_on:
    - konnect
---

This page describes how {{site.webhook_engine}} works and how its entities interact.
The engine receives events through listeners and channels, stores accepted events in Postgres, and delivers them through subscriptions.
Each entity has a specific role in that flow, and the sections that follow explain each step of it.

## How it works

Event ingestion follows this flow:

1. An HTTP client sends an event with a `POST` request to a path on a listener.
2. The listener routes the request to the channel that owns the path.
3. The channel applies its ordered ingest policy chain to the event.
4. The engine stores the accepted event in Postgres.
5. Each subscription on the channel evaluates its condition against the event.
   If the condition matches, or if the subscription doesn't have a condition, the subscription delivers the event.
6. The request-phase delivery policies process the outbound request, and the engine sends it to the subscription's endpoint. The response-phase policies then process the endpoint's response.

When the channel accepts an event, it returns an accepted status to the publisher.

The following diagram illustrates the flow:

<!--vale off-->
{% mermaid %}

flowchart LR

  Client["HTTP client<br/>(publisher)"]

  subgraph WHE ["Webhook Engine"]
    direction LR
    Listener["Listener<br/>addresses + port"]
    Channel["Channel<br/>HTTP source (paths, auth)<br/>ingest policies"]
    Store[("Postgres<br/>event store")]
    SubA["Subscription A<br/>condition<br/>delivery policies"]
    SubB["Subscription B<br/>condition<br/>delivery policies"]
    SubN["Subscription N<br/>condition<br/>delivery policies"]
  end

  Client--"POST event"-->Listener-->Channel
  Channel--"accepted events"-->Store
  Store--"matching events"-->SubA--"HTTP(S) delivery"-->EndpointA["Subscriber A<br/>endpoint"]
  Store--"matching events"-->SubB--"HTTP(S) delivery"-->EndpointB["Subscriber B<br/>endpoint"]
  Store--"..."-->SubN--"HTTP(S) delivery"-->EndpointN["Subscriber N<br/>endpoint"]

{% endmermaid %}
<!--vale on-->

_**Figure 1**: The {{site.webhook_engine}} event flow._

### {{site.webhook_engine}} entities

In {{site.webhook_engine}}, an entity is a component or object that makes up the {{site.webhook_engine}} and its ecosystem.
Entities represent the various building blocks used to configure and manage {{site.webhook_engine}}, and each entity has a specific role.

{{site.webhook_engine}}'s workflow is composed of the following core entities:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
rows:
  - entity: Listener
    description: |
      A listener defines the IP addresses and TCP port at which the engine accepts HTTP `POST` requests from publishers.
      HTTP-sourced channels are exposed on a listener.
  - entity: Channel
    description: |
      A channel receives events from exactly one source and applies an ordered ingest policy chain to each ingested event.
      The only source type is `http`, which receives events over HTTP `POST` on a listener at one or more paths.
      The HTTP source authenticates incoming requests with one auth method.
  - entity: Subscription
    description: |
      A subscription belongs to one channel and delivers matching events of that channel to an HTTP(S) endpoint.
      A user-definable condition decides, per event, whether the event is delivered to the subscription.
      Delivery policies run in an ordered two-phase chain, a request phase followed by a response phase.

{% endtable %}
