---
title: How do I configure rate limiting on Consumer Groups?
content_type: support
description: "After upgrading {{site.base_gateway}}, use the recommended method for configuring rate limiting on Consumer Groups: scope the Rate Limiting plugin directly to the Consumer Group."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I configure rate limiting on Consumer Groups after upgrading?
  a: |
    The `overrides` endpoint and `enforce_consumer_groups` option were deprecated in 3.4.
    The recommended approach is to scope the Rate Limiting plugin directly to the Consumer Group
    using the `/consumer_groups/{id}/plugins` endpoint.
related_resources:
  - text: Rate Limiting plugin
    url: /plugins/rate-limiting/
  - text: Consumer Groups entity
    url: /gateway/entities/consumer-group/
  - text: Known limitations of dynamic plugin ordering
    url: /gateway/entities/plugin/#known-limitations-of-dynamic-plugin-ordering
---

## Problem

Before 3.4, the recommended way to configure rate limiting on Consumer Groups was to use the
`/consumer_groups/{id}/overrides/plugins/rate-limiting-advanced` endpoint, combined with the
`enforce_consumer_groups` option on a global plugin instance.
Both were deprecated in 3.4.

If you're upgrading and used this approach, switch to scoping the Rate Limiting plugin directly
to the Consumer Group instead.

{:.info}
> **Note:** If dynamic ordering is configured anywhere in the Workspace, there are limitations with executing the Rate Limiting plugin at the Consumer or Consumer Group level. Plugins may not work if they are Consumer/Consumer Group scoped.
This has been fixed in 3.14.

## Solution

1. Create a Consumer Group if you haven't already, for example `free-tier`:

   ```bash
   curl -X POST http://localhost:8001/consumer_groups \
     --data name=free-tier
   ```

2. Add Consumers to the group:

   ```bash
   curl -X POST http://localhost:8001/consumer_groups/free-tier/consumers \
     --data consumer.username=my-consumer
   ```

3. Scope the Rate Limiting plugin to the Consumer Group. For example, to allow 10 requests per minute using the local policy:

   ```bash
   curl -X POST http://localhost:8001/consumer_groups/free-tier/plugins \
     --data name=rate-limiting \
     --data config.minute=10 \
     --data config.policy=local
   ```

The plugin now enforces the rate limit for all Consumers in the `free-tier` group.
