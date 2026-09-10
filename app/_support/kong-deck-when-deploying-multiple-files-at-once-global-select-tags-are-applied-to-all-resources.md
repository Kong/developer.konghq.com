---
title: "Kong decK: When deploying multiple files at once, global `select_tags` are applied to all resources"
content_type: support
description: Both resources are applying the global tags values as they are being applied at the same time.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do decK's global `select_tags` apply to all resources when deploying multiple files at once?
  a: |
    When deploying multiple files together, the `select_tags` values from each file are all applied globally at the same time, so every resource ends up with the combined tags instead of just the ones in its own file. To keep tags scoped per resource, set specific resource-level `tags` instead of relying on `select_tags`.
related_resources: []
---

## Problem

We are trying to deploy multiple files at once to {{site.base_gateway}} using decK, all with different tags. However, we noticed that all resources created contain the same tags even though the file specifies different tags.

For example:

File 1:

```yaml
_format_version: "3.0"
_info:
  defaults: {}
  select_tags:
  - global
  - global-auth
```

File 2:

```yaml
_format_version: "3.0"
_info:
  defaults: {}
  select_tags:
  - global
  - global-no-auth
```

Sample command:

```bash
deck gateway sync --kong-addr 'http://localhost:8001/' --headers 'kong-admin-token:token' plugin1.yaml plugin2.yaml
```

How can we resolve this issue?

## Solution

Both resources are applying the global tags values as they are being applied at the same time. To resolve this, we need to move from `select-tags` to specific resource tags.

Example:

```yaml
_format_version: "3.0"
_info:
  defaults: {}
  select_tags:
  - global
_workspace: testworkspace
plugins:
- config:
  ...
  enabled: true
  name: openid-connect
  tags:
  - global-oidc-auth
```

```yaml
_format_version: "3.0"
_info:
  defaults: {}
  select_tags:
  - global
_workspace: testworkspace
plugins:
- config:
  ...
  enabled: true
  name: pre-function
  tags:
  - global-no-auth
```

Now if we run the sync command - both resources get created with the specific tags.

```bash
deck gateway sync --kong-addr 'http://localhost:8001/' --headers 'kong-admin-token:token' plugin1.yaml plugin2.yaml
```
