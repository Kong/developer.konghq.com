---
title: "\"Database already bootstrapped\" messages when upgrading Kong with Helm"
content_type: support
description: Reinstalling (rather than upgrading) the Kong Helm chart causes the init-migrations job to report "Database already bootstrapped" because the database has already been bootstrapped by a prior install; follow the Helm upgrade procedure instead.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why does Kong's Helm upgrade report "Database already bootstrapped"?
  a: |
    This happens when the Kong Helm chart was uninstalled and reinstalled instead of upgraded — `helm install` always runs `kong migrations bootstrap`, which fails against a database that a previous install already bootstrapped. Use `helm upgrade` instead, which runs `kong migrations up` and `kong migrations finish`, after bumping the image tag in `values.yaml`.
related_resources: []
---

## Problem

When attempting to upgrade Kong using Helm, the `kong-init-migrations` pod reports:

```
Database already bootstrapped
```

Additionally, reviewing the Kong pod logs will show:

```
Run with --v (verbose) or --vv (debug) for more details
waiting for db
Error: /usr/local/share/lua/5.1/kong/cmd/utils/migrations.lua:30: New migrations available; run 'kong migrations up' to proceed
```

## Cause

This issue occurs when the chart is uninstalled and reinstalled rather than upgraded.

## Solution

When upgrading via Helm you should follow the below procedure.

1. Change the version of Kong in the `values.yaml` to the desired target. For example, if you are upgrading from 3.10.0.0 to 3.14.0.0 you should change

   ```yaml
   image:
     repository: kong-docker-kong-enterprise-edition-docker.bintray.io/kong-enterprise-edition
     tag: 3.10.0.0
   ```

   to

   ```yaml
   image:
     repository: kong-docker-kong-enterprise-edition-docker.bintray.io/kong-enterprise-edition
     tag: 3.14.0.0
   ```

2. Upgrade the chart

   ```bash
   helm upgrade my-kong kong/kong -n kong --values ./values.yaml
   ```

When `helm install` is run this causes the installation to run `kong migrations bootstrap`, whereas running `helm upgrade` will run `kong migrations up` and `kong migrations finish`.
