---
title: "Channels"
content_type: reference
layout: gateway_entity

description: |
  Channels are {{site.webhook_engine}} entities that process each event through an ingest policy chain before the engine stores it.
related_resources:
  - text: "{{site.webhook_engine}}"
    url: /webhook-engine/
  - text: "Architecture"
    url: /webhook-engine/architecture/

products:
  - webhook-engine

breadcrumbs:
  - /webhook-engine/

tools:
  - konnect-api

works_on:
  - konnect
---

## What is a channel?

A channel applies an ordered ingest policy chain to each event it receives, and the engine stores the events that the channel accepts.
Every channel has exactly one source.

## Set up a channel

A channel needs a [listener](/webhook-engine/entities/listener/).
A channel's HTTP source references a listener, and the listener routes `POST` requests on the channel's paths to the channel.

By default, the engine returns `202 Accepted` when it accepts an event.
Set `accepted_status` to `200` for senders that only treat `200` as success.

Each policy in the ingest policy chain can have a user-definable condition that decides whether the policy applies to an event. Each policy also has a failure mode that controls what the engine does with the event when the policy fails. By default, the engine rejects the event.

## Schema

<!-- TODO: add entity schema when the API is fully released -->

