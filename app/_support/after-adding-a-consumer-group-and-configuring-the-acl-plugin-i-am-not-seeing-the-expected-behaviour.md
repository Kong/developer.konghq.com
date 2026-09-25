---
title: After adding a Consumer Group and configuring the ACL plugin I am not seeing the expected behaviour
content_type: support
description: "By default, the ACL plugin only evaluates ACL group credentials added directly to the Consumer; setting `config.include_consumer_groups: true` lets Consumer Groups be used directly in the allow/deny list."
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do I still get an HTTP 401 from the ACL plugin after adding my Consumer to a Consumer Group that's listed in `Config.Allow`?
  a: |
    By default, the ACL plugin only checks ACL group credentials added directly to a Consumer — Consumer Group membership alone doesn't satisfy a `Config.Allow`/`Config.Deny` entry. Setting `config.include_consumer_groups: true` on the ACL plugin lets Consumer Group names be used directly in the allow/deny list, without requiring a separate ACL credential on each Consumer.
related_resources:
  - text: documentation for the Rate Limiting Advanced plugin
    url: /plugins/rate-limiting-advanced/#rate-limiting-for-consumer-groups
  - text: documentation for Consumer Groups
    url: /gateway/kong-enterprise/consumer-groups/
---

## Problem

After creating a Consumer Group and adding my Consumer into it under Consumers > Consumer Groups, I am still seeing an HTTP 401 from the ACL plugin when calling the Route, even with the same Consumer Group added into the ACL plugin's `Config.Allow` list.

## Cause

By default, the ACL plugin only evaluates ACL group credentials that have been added directly to the Consumer under Consumers > `Consumer_name` > Credentials. Simply adding a Consumer to a Consumer Group does not, on its own, satisfy an ACL plugin `Config.Allow`/`Config.Deny` entry, which is why the request still returns 401/403 from the ACL plugin even though the same Consumer Group name is also listed in the plugin's `Config.Allow` list.

## Solution

The ACL plugin supports a `config.include_consumer_groups` setting (default `false`). Setting this to `true` allows Consumer Group names to be used directly in the ACL plugin's allow/deny lists, without requiring a separate ACL credential on the Consumer, for example:

```yaml
- name: acl
  config:
    include_consumer_groups: true
    allow:
    - my_consumer_group
```

With `include_consumer_groups: true`, any Consumer that belongs to `my_consumer_group` is allowed through, based purely on Consumer Group membership. This is the direct fix for the scenario, and is generally simpler than adding an individual ACL credential to every Consumer in the group.

Consumer Groups are also usable independently of the ACL plugin — most commonly to scope the Rate Limiting Advanced plugin per group, as per the documentation for the plugin and the documentation for Consumer Groups. If you want to keep ACL group-based access control entirely separate from Consumer Group membership, the ACL plugin still requires an ACL credential to be added to the Consumer in Consumers > `Consumer_name` > Credentials, and it is that ACL group (not the Consumer Group) which must appear in the plugin's `Config.Allow` or `Config.Deny` list.
