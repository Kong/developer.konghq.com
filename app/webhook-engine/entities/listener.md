---
title: "Listeners"
content_type: reference
layout: gateway_entity

description: |
  Listeners are {{site.webhook_engine}} entities that bind IP addresses and a TCP port at which the engine accepts HTTP `POST` requests.
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

## What is a listener?

A listener defines the IP addresses and TCP port at which the engine accepts HTTP `POST` requests.
HTTP-sourced channels are exposed on a listener.

## Set up a listener

A listener needs at least one IP address and a TCP port between 1 and 65535.

## Schema

<!-- TODO: add entity schema when the API is fully released -->

