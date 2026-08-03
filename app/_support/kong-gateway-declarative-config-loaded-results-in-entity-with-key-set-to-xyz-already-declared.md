---
title: "Kong Gateway: Declarative config loaded results in \"entity with key set to 'xyz' already declared\""
content_type: support
description: The declarative configuration provided is resulting in this due to multiple keys defined with the same value.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Kong Gateway fail to start with "entity with key set to 'xyz' already declared" in a declarative config?
  a: |
    This uniqueness violation happens when the declarative config has multiple entries defining the same key value, often from merging configs from different environments. Remove the duplicate or make each key unique to resolve it.
related_resources: []
---

## Problem

We are starting Kong Gateway with a declarative Configuration file we are receiving the following error:

```

kong-dbless  | 2023/12/04 17:18:26 [error] 1#0: init_by_lua error: /usr/local/share/lua/5.1/kong/init.lua:722: error parsing declarative config file /home/kong.yaml:
kong-dbless  | in 'keyauth_credentials':
kong-dbless  |   - in entry 1 of 'keyauth_credentials': uniqueness violation: 'keyauth_credentials' entity with key set to 'TestKey123' already declared
```

Kong won't start up successfully - How can we resolve this?

## Solution

The declarative configuration provided is resulting in this due to multiple keys defined with the same value. This may happen if the declarative config from 2 different environments was merged resulting in 2 different users with the same key.

i.e.

```yaml
- key: TestKey123
username: tst--dev
custom_id: "tst--dev"
```

```yaml
- key: TestKey123
username: tst--uat
custom_id: "tst--uat"
```

To resolve this, we need to either remove the value or modify it to be unique.
