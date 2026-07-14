---
title: 'Consumer Consistency'
name: 'Consumer Consistency'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Enforce that all stacked authentication factors resolve to the same Consumer'

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

icon: consumer-consistency.png

categories:
  - authentication

search_aliases:
  - consumer-consistency
  - same consumer
  - multi-factor authentication
  - stacked authentication

min_version:
  gateway: '3.16'

related_resources:
  - text: Authentication
    url: /gateway/authentication/
  - text: Allow multiple authentication methods
    url: /how-to/allow-multiple-authentication/
  - text: ACL
    url: /plugins/acl/
---

The Consumer Consistency plugin enforces that when multiple authentication plugins are stacked on the
same Gateway Service or Route, every credential presented resolves to the **same** [Consumer](/gateway/entities/consumer/).
If the factors resolve to different Consumers, the request is rejected with `403`.

## The problem it solves

When you stack authentication plugins on a Route with `config.anonymous` unset (a logical AND, where
every factor must pass), {{site.base_gateway}} validates each credential but does **not** bind the
factors to a single identity. Each authentication plugin authenticates independently and calls the
same internal setter, which overwrites the authenticated Consumer — the last plugin executed
(determined by [plugin priority](/gateway/entities/plugin/#plugin-priority)) wins.

For example, with [Key Authentication](/plugins/key-auth/) (priority 1250),
[Basic Authentication](/plugins/basic-auth/) (1100), and [ACL](/plugins/acl/) (950):

1. Key Auth runs and sets the Consumer to whoever owns the API key.
2. Basic Auth runs and **overwrites** the Consumer to whoever owns the Basic Auth credential.
3. ACL checks only that final Consumer.

So a valid API key from **Consumer B** plus valid Basic Auth from **Consumer A** passes the whole
chain — Consumer B is overwritten before ACL runs, so its group membership is never evaluated.
Stacking authentication plugins is therefore **not** equivalent to multi-factor authentication for a
single identity.

## How it works

Attach the Consumer Consistency plugin to the Service or Route that stacks the authentication plugins.
{{site.base_gateway}} records the Consumer that each authentication factor resolves to. The plugin
runs after all authentication plugins but **before authorization** ([ACL](/plugins/acl/) and others)
and:

* Allows the request when every factor resolved to the same Consumer.
* Rejects the request with `403` when the factors resolved to different Consumers.

Running before authorization is deliberate. {{site.base_gateway}} evaluates access control against a
single authenticated Consumer, so once two factors resolve to different Consumers the request is
ambiguous for every Consumer-scoped policy — ACL, rate limiting, the upstream `X-Consumer-*` headers,
and Consumer-based upstream hashing. Rejecting the request before any of them run means authorization
is never evaluated against an ambiguous identity, and a rejected request never counts against a
rate-limit counter or reaches the upstream service.

## Prerequisites

* **Do not set `config.anonymous`** on the stacked authentication plugins. Setting `config.anonymous`
  turns the chain into a logical OR, where plugins stop authenticating once one Consumer is set — only
  a single factor resolves, so there is nothing to compare. This plugin is for strict AND stacking,
  which is the configuration with the gap.
* Only Consumer-based authentication is checked. Credential-only or principal-based authentication that
  doesn't map to a Consumer isn't affected.

## Example

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
    - name: basic-auth
    - name: acl
      config:
        allow:
          - my-group
    - name: consumer-consistency
formats:
  - deck
{% endentity_examples %}

With this configuration, a request must present a valid API key **and** valid Basic Auth credentials
that both belong to the same Consumer. A request whose two credentials belong to different Consumers is
rejected with `403`, even if the surviving identity would otherwise pass the ACL check.
