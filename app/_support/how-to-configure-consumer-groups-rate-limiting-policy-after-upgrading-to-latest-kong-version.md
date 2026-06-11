---
title: Configuring Consumer Groups Rate Limiting Policy after upgrading to the latest Kong version
content_type: support
description: After upgrading Kong gateway to latest version, the method for configuring the Rate Limiting Policy / Rate limiting plugin for Consumer Groups has changed.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I configure the Consumer Groups Rate Limiting Policy after upgrading to the latest Kong version?
  a: |
    After upgrading (for example, from `3.4.3.13` to `3.10.0.x`), the Consumer Group policy is
    deprecated and policies are now applied through the Plugins tab instead of the Policy tab. Use
    the Admin API endpoint `/consumer_groups/{group_name_or_id}/overrides/plugins/rate-limiting-advanced`
    to configure the policy, then create a Rate Limiting plugin instance with the
    `enforce_consumer_groups` option enabled and add your Consumer Group to the list. Note that if
    Dynamic Ordering is configured anywhere in the workspace, consumer/consumer group scoped Rate
    Limiting plugins may not work.
related_resources:
  - text: Known limitations of dynamic plugin ordering
    url: /gateway/entities/plugin/#known-limitations-of-dynamic-plugin-ordering
  - text: Kong Admin API documentation
    url: /api/gateway/admin-ee/#/operations/put-consumer_groups-group_name_or_id-overrides-plugins-rate-limiting-advanced
---

## Overview

How to configure Consumer Groups Rate Limiting Policy after upgrading from Kong version 3.4.3.13 to 3.10.0.x or in latest version where consumer group policy is deprecated.

## Steps

After upgrading Kong gateway to latest version, the method for configuring the Rate Limiting Policy / Rate limiting plugin for Consumer Groups has changed. Previously, the policy could be configured directly in the Consumer Group's policy section. However, in latest versions, the configuration process has been updated, and policies now need to be applied through the Plugins tab.

Also, it's important to note that if Dynamic Ordering is configured anywhere in the workspace, there are limitations with executing the Rate Limiting plugin at the Consumer or Consumer Group level and the plugins may not work if they are consumer/consumer group scoped.  There is an improvement to support Dynamic Plugin Ordering for Consumer/Consumer Group scoped plugins.

Consumer groups -> Policy tab in older versions:

Consumer Groups --> Policy Tab is disabled

Consumer Groups --> Configure Plugins directly

NOTE: The consumer groups policy configuration still works in latest versions. It is not removed as we hope customers will organically move to new model over the time.

To correctly configure the Rate Limiting Advanced plugin for a Consumer Group in latest Kong version, follow these steps:

1. Use the Admin API to configure the policy for your newly created Consumer Groups (In above example, I have created "free-150tps" consumer group and we can see that there is no option to configure policy in latest version.

   The relevant API endpoint is `/consumer_groups/{group_name_or_id}/overrides/plugins/rate-limiting-advanced`.

   For detailed API documentation, refer to the Kong Admin API documentation.

   Example:

   ```bash
   curl -X PUT https://adminapi:8001/consumer_groups/<consumer_group_id/name>/overrides/plugins/rate-limiting-advanced \
   -H 'content-type: application/json' \
   -d '{"config":{"limit": [10], "window_size":[10], "window_type":"sliding"}}'
   ```

2. Create a Rate Limiting plugin instance and enable the `enforce_consumer_groups` option. Add the name of your Consumer Group "free-150tps" to the list.

3. Confirm that the Rate Limiting works as per the policy configured. This setup should now correctly enforce the specified TPS (Transactions Per Second) limit for any consumer added to this Consumer Group "free-150tps".
