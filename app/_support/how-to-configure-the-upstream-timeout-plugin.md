---
title: How to configure the `upstream-timeout` plugin
content_type: support
description: "Learn how to configure the `upstream-timeout` plugin, which overrides service-level timeout settings for connecting to, reading from, and sending to upstream targets."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: explained here
    url: /gateway/traffic-control/proxying/#proxying-and-upstream-timeouts
tldr:
  q: How do I configure the `upstream-timeout` plugin?
  a: |
    The `upstream-timeout` plugin overrides timeouts configured at the service level. Set `config.read_timeout`, `config.send_timeout`, and `config.connect_timeout` (in milliseconds) when enabling the plugin globally, or on a service or route, using the Admin API or a `KongClusterPlugin` resource on Kubernetes.
---

## Overview

How do I configure the `upstream-timeout` plugin?

## Steps

The `upstream-timeout` plugin overrides the timeouts configured at a service level.

The configuration parameters are:

`config.read_timeout`: Reading from upstream timeout threshold in milliseconds

`config.send_timeout`: Send to upstream timeout threshold in milliseconds

`config.connect_timeout`: Connect to upstream timeout threshold in milliseconds

The plugin can be enabled globally, on a service or a route, same as other plugins. For example, to enable the plugin on a route with a `read_timeout` set to override any service-configured `read_timeout`:

```bash
curl -X POST http://<kong-admin-api>:8001/routes/{route_id}/plugins --header "kong-admin-token: <token>" \
--data "name=upstream-timeout" \
--data "config.read_timeout=4000"
```

If the target Route was created without an explicit `protocols` field, Kong Gateway defaults it to `["https"]` only (not `["http","https"]`), so a plain `http://` request to that route returns `426 Please use HTTPS protocol` regardless of this plugin. Set `protocols` explicitly (e.g. `["http","https"]`) when creating the Route if you need plain-HTTP access.

### To enable the plugin on Kubernetes

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongClusterPlugin
metadata:
  name: global-upstream
  annotations:
    kubernetes.io/ingress.class: kong
  labels:
    global: "true"
config:
  read_timeout: 4000
plugin: upstream-timeout
```
