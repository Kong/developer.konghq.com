---
title: Federated configuration with decK
description: Allow independent teams to manage their own configuration in a distributed way

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/apiops/

related_resources:
  - text: APIOps KongAir example
    url: /deck/apiops/

tags:
  - federated-config
  - declarative-config
---

As shown in the [APIOps example](/deck/apiops/), decK enables a completely federated API management process.

- Application teams can work with OpenAPI files as the source of truth
- If they want to add Kong specific configuration, they can patch it in
- Platform teams can layer on required policies
- State files can be linted for unwanted configuration, for example, non-HTTPS Routes

## Federated management example

AcmeCorp is building their new SaaS platform on top of {{ site.base_gateway }}. They want application teams to manage their own routing configuration, but also need to ensure that the APIs are secured appropriately.

To meet their needs, they split their configuration into multiple files:

- `team-a.yaml`
- `team-b.yaml` through`team-z.yaml`
- `consumers.yaml`
- `platform-security-plugins.yaml`
- `platform-rate-limiting-plugins.yaml`

Each of these files contains a subset of the configuration needed to run {{ site.base_gateway }} for AcmeCorp.

### Application team configs

Each of the application team configurations contains routing information only. It uses `select_tags` to ensure that only entities owned by that team are updated when `deck gateway sync` is run.

```yaml
# team-a.yaml
# Contains services + routes
_format_version: "3.0"
_info:
  select_tags:
    - team-a
services:
  - name: users
    url: https://example.com/users
    routes:
      - name: Passthrough
        paths: [/]
```

```yaml
# team-b.yaml
# Contains services + routes
_format_version: "3.0"
_info:
  select_tags:
    - team-b
services:
  - name: widgets
    url: https://widgets.example.com/
    routes:
      - name: count
        paths: [/count]
      - name: stats
        paths: [/stats]
```

### Consumer management

The users and systems that consume AcmeCorp's APIs are independent of any team. To ensure that Consumers can call the AcmeCorp APIs, decK is used to create Consumers and credentials:

```yaml
# consumers.yaml
# Managed by a central team
_format_version: "3.0"
_info:
  select_tags:
    - consumers
consumers:
  - username: alice
    keyauth_credentials:
      - key: hello_alice
  - username: bob
    keyauth_credentials:
      - key: hello_bob
  - username: charlie
    keyauth_credentials:
      - key: hello_charlie
```

### Platform security

To ensure that the APIs are only accessed by authorized users, the platform team applies a global `key-auth` plugin:

```yaml
_format_version: "3.0"
_info:
  select_tags:
    - security-plugins
plugins:
  - name: key-auth
```

### Rate Limiting

Finally, the platform team wants to add a rate limiting plugin to the `users` Service to protect the underlying database.

They could work with `team-a` to add the plugin in the team's configuration file, but the platform team want to be able to change values rapidly based on monitoring data. To enable this, the platform team chooses to layer on the rate limiting configuration independently of `team-a`'s configuration.

```yaml
_format_version: "3.0"
_info:
  select_tags:
    - plugins-rate-limit
  default_lookup_tags:
    services:
      - team-a
plugins:
  - name: rate-limiting
    service: users
    config:
      minute: 10
```

As this configuration uses a different `select_tags` value, it won't be edited by `team-a` when they run `deck gateway sync`. The use of `default_lookup_tags` allows the platform team to reference the `users` Service even though it has different tags.

The example above shows how multiple application and platform teams can manage their configuration independently. Each application team can focus on routing requests to their Service while the platform team handles security and stability concerns.
