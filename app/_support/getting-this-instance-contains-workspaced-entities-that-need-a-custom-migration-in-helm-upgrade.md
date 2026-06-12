---
title: "Getting `This instance contains workspaced entities that need a custom migration` in Helm upgrade"
content_type: support
description: "This error during a Helm upgrade usually means you are using an older chart version; update the Helm repo and rerun the upgrade."
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: "Why does my Helm upgrade fail with `This instance contains workspaced entities that need a custom migration`?"
  a: |
    This error during the `helm upgrade` is usually because you are using an older chart version.
    Update the Helm repo locally with `helm repo update`, then rerun the upgrade, for example:

    ```bash
    helm upgrade kong-test -f values.yaml kong/kong --set migrations.preUpgrade=true --set migrations.postUpgrade=false
    ```
related_resources: []
---

## Problem

After running the `helm upgrade` command, the `wait-for-db` container fails and prints:

```
This instance contains workspaced entities that need a custom migration.
please use the provided helpers to migrate them:
kong migrations upgrade-workspace-table vaults_beta
Error: nginx not running in prefix: /tmp/tmp.okiPjN Run with --v (verbose) or --vv (debug) for more details
```

## Cause

This error during the upgrade is usually because you are using an older chart version.

## Solution

1. Make sure the Helm repo is updated locally:

   ```bash
   helm repo update
   ```

2. Then proceed with the Helm upgrade:

   ```bash
   helm upgrade kong-test -f values.yaml kong/kong --set migrations.preUpgrade=true --set migrations.postUpgrade=false
   ```

You can find more information about the Helm upgrade in the Kong Helm Chart documentation.
