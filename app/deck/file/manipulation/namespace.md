---
title: deck file namespace
description: Apply a namespace to Routes in a decK file by path or hostname.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/file/
  - /deck/file/manipulation/

related_resources:
  - text: All decK documentation
    url: /index/deck/
---

When practicing [federated configuration management](/deck/apiops/federated-configuration/), there is a high chance of endpoint collision where two teams unexpectedly use the same API path.

To avoid this, you can namespace each API using a path prefix or have each API listen on a specific host.

By default, the `deck file namespace` command operates on all Routes in a file. To target specific Routes, pass the `--selector` flag.

## Path prefix

The simplest way to prevent collisions is to prefix each API Route with a static path. In this case, all Routes in `/path/to/config` will be exposed under a `/billing` path:

```bash
deck file namespace --path-prefix=/billing -s /path/to/config.yaml
```

To remain transparent to the backend Services, the added path prefix must be removed from the path before the request is Routed to the Service. To remove the prefix, the following approaches are used (in order):

1. If the Route has `strip_path=true`, then the added prefix will already be stripped.
1. If the related Service has a `path` property that matches the prefix, then the `service.path` property is updated to remove the prefix.
1. A `pre-function` plugin will be added to remove the prefix from the path.

{:.important}

> If a `pre-function` is used, this will take priority over any global `pre-function` plugin that you have configured.

## Custom host

An alternate way to namespace APIs is to have each API listen on a different hostname, for example, `http://service1.api.example.com/somepath`, `http://service2.api.example.com/somepath`.

The following command updates all Route definitions in a file to listen only when a request is made to `service1.api.example.com`. If the Route already has a `hosts` entry, the new domain is appended to the list.

```bash
deck file namespace --host service1.api.example.com
```

If you need to ensure that the API only listens on the hostname provided, you can pass the `--clear-hosts` flag:

```bash
deck file namespace --host service1.api.example.com --clear-hosts
```
