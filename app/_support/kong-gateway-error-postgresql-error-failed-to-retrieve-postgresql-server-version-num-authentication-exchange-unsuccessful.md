---
title: "{{site.base_gateway}}: \"Error: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: authentication exchange unsuccessful\""
content_type: support
description: This error means your `PG_PASSWORD` parameter does not match the password set on the database.
products:
  - gateway
works_on:
  - on-prem
  - konnect
published: false
tldr:
  q: "Why does {{site.base_gateway}} show \"failed to retrieve PostgreSQL server_version_num: authentication exchange unsuccessful\" on startup?"
  a: |
    Your `PG_PASSWORD` doesn't match the password set on the PostgreSQL database. The messaging differs by version: PostgreSQL 14 reports this generic exchange error, while PostgreSQL 13 reports the more explicit `FATAL: password authentication failed for user "kong"`.
related_resources: []
---

## Problem

When starting up our new instance of {{site.base_gateway}}, we see the following error:

```

Error: [PostgreSQL error] failed to retrieve PostgreSQL server_version_num: authentication exchange unsuccessful
```

We are using PostgreSQL 14.X

## Solution

This error means your `PG_PASSWORD` parameter does not match the password set on the database.

The messaging has changed between PostgreSQL 13 and PostgreSQL 14.

Example of PostgreSQL 13 password messaging:

```

[PostgreSQL error] failed to retrieve PostgreSQL server_version_num: FATAL: password authentication failed for user "kong"
```
