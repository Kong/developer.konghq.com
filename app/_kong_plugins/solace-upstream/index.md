---
title: 'Solace Upstream'
name: 'Solace Upstream'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Transform requests into Solace messages in a Solace queue or topic'
beta: true

products:
  - gateway

works_on:
  - on-prem
  - konnect

tags:
  - traffic-control
  - events
  - solace

min_version:
  gateway: '3.11'

icon: solace.png

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

categories:
  - transformations

search_aliases:
  - solace-upstream
  - events
  - protocol mediation
---

This plugin converts requests (or custom data) into [Solace](https://solace.com/) messages and publishes them to specified
Solace queues or topics. For more details, see [Solace event messaging overview](https://docs.solace.com/Messaging/messaging-overview.htm).

## Implementation details

This plugin uses the official [Solace C API](https://docs.solace.com/API/Messaging-APIs/C-API/c-api-home.htm) as the client
when communicating with the Solace server.

When encoding request bodies, several things happen:

* For requests with a content-type header of `application/x-www-form-urlencoded`, `multipart/form-data`,
  or `application/json`, this plugin passes the raw request body in the `body` attribute, and tries
  to return a parsed version of those arguments in `body_args`. If this parsing fails, an error message is
  returned and the message is not sent.
* If the `content-type` is not `text/plain`, `text/html`, `application/xml`, `text/xml`, or `application/soap+xml`,
  then the body will be base64-encoded to ensure that the message can be sent as JSON. In such a case,
  the message has an extra attribute called `body_base64` set to `true`.

