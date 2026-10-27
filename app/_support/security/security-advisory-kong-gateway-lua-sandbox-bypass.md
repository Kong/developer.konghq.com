---
title: "Security Advisory: {{site.base_gateway}} Lua sandbox bypass"
content_type: support
description: "A medium-severity vulnerability lets users with plugin configuration privileges bypass the Lua sandbox in the Pre-Function and Post-Function plugins and run SQL commands on the database. This advisory describes the impact and the workarounds."
products:
  - gateway
works_on:
  - on-prem
  - konnect
advisory:
  severity: medium
---

{{site.base_gateway}} contains a medium-severity vulnerability that allows authenticated users with plugin configuration privileges to bypass Lua sandbox restrictions and execute arbitrary SQL commands on the backend PostgreSQL database. The vulnerability stems from incomplete access restrictions on Plugin Development Kit (PDK) global objects. It allows access to database connector objects through alternative code paths.

## Issue

{{site.base_gateway}} provides sandboxed command execution plugins (Post-Function and Pre-Function) that are intended to run user-supplied Lua code in a restricted environment. The vulnerability arises because the PDK global objects are accessible within the sandbox environment through the `kong.*` namespace.

{{site.base_gateway}} implements a denylist mechanism to restrict access to sensitive attributes such as `kong.cache.cluster_events` and `kong.db.connector.config`. This protection is incomplete and can be bypassed.

## Impact

This vulnerability can only be exploited by a user who has been granted an RBAC policy that allows configuration rights for the Pre-Function or Post-Function plugin in a workspace. That user can create a plugin with the problematic script.

In {{site.konnect_product_name}} and hybrid mode, this issue impacts the confidentiality of the system. A user with a potentially very restricted RBAC policy can dump the entire {{site.base_gateway}} configuration.

In traditional mode, the issue also impacts the integrity and availability of the system, because the user can drop the entire database schema.

## Solution

Kong has released patches on supported versions of {{site.base_gateway}} and recommends upgrading to the latest patch version to address this issue.

## Workarounds

* Restrict the RBAC roles that can configure the Pre-Function and Post-Function plugins.
* Disable the serverless plugins if you don't need them by setting `untrusted_lua = off`.
* Ensure that the database accounts used by {{site.base_gateway}} are least-privileged.
