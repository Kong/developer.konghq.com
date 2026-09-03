---
title: "{{site.base_gateway}}: Key-Auth on Consumer isn't working with Vault secrets"
content_type: support
description: This is expected behavior at this time as there is no support yet for referenceable fields in the `key-auth` plugin.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: Why doesn't referencing a Vault secret work for the `key-auth` plugin's `key` field on a Consumer?
  a: |
    Referenceable fields aren't yet supported in the `key-auth` plugin (tracked as GTWY-I-549), so a Vault reference is taken as a literal string instead of being resolved.
    Check whether a field is referenceable by looking for "referenceable" in its attributes, as with the `client_id` field in the `openid-connect` plugin.
---

## Problem

We are trying to reference a Vault secret for the Key Authentication (`key-auth`) plugin field `key` on a Consumer, but it's not working at all and appears to be taking the value as a literal string instead.

An error may be seen when running a decK sync command for example as below:

```bash
> deck sync --konnect-runtime-group-name development
Error: reading file: validating file content: 1 errors occurred:
consumers.0.keyauth_credentials.0.key: Invalid type. Expected: string, given: object
```

## Solution

This is expected behavior at this time as there is no support yet for referenceable fields in the `key-auth` plugin. This is a feature request filed as GTWY-I-549 for inclusion in the future. To know which values are referenceable by Vault, the configuration property must include "referenceable" in the attributes of it such as it does on this field in the OpenID Connect (`openid-connect`) plugin for the `client_id` field. We also have a dedicated documentation page which lists all the fields that are referenceable at a glance.
