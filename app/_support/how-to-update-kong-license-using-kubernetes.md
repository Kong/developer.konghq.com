---
title: How to update Kong license using Kubernetes
content_type: support
description: Update a Kong Enterprise license on Kubernetes by creating a new license secret and upgrading the Helm deployment, or by editing the deployment directly.
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: How do I update Kong's license when running on Kubernetes?
  a: |
    Create a new Kubernetes secret from the updated license file, then either point `license_secret` in your Helm `values.yaml` at the new secret name and run `helm upgrade`, or edit the `KONG_LICENSE_DATA` secret name directly on the deployment. Either approach triggers a pod replacement that picks up the new license. If a Helm upgrade fails, `helm rollback` reverts to the previous revision.
---

## Overview

How can I update Kong's license if I'm using Kubernetes?

## Steps

If you deployed Kong using the Helm chart, the best way to upgrade the license is to create a new secret and update the Helm deploy:

1. Create a new license secret using the new license file:

   ```bash
   kubectl -n <kong-namespace> create secret generic kong-enterprise-license2 --from-file=./license
   ```

2. Update the `values.yaml` file you used for the initial Helm deployment, and change `license_secret: kong-enterprise-license` to `license_secret: kong-enterprise-license2`.

3. Upgrade the Helm deployment:

   ```bash
   helm upgrade -n <kong-namespace> <kong-app-name> kong/kong -f values.yaml
   ```

If you don't want to use Helm upgrade, you can also edit your Kubernetes deployment using the following commands, and that will trigger the pod replacement with the new license, instead of the above steps 2 and 3:

2. Edit the Kubernetes deployment:

   ```bash
   kubectl edit deployment/<kong-deployment> -n <kong-namespace>
   ```

3. Search for `name: KONG_LICENSE_DATA`, and edit `name: kong-enterprise-license` to `name: kong-enterprise-license2` and save the change.

It is always recommended to test this beforehand in a non-production environment to see what exactly happens before rolling this out in production.

If you need to rollback, using Helm:

1. Check deploy history:

   ```bash
   helm -n <kong-namespace> history <kong-app-name>
   ```

   ```
   REVISION UPDATED STATUS CHART APP VERSION DESCRIPTION
   1 Tue Dec 7 07:16:48 2026 deployed kong-3.4.1 3.14 Install complete
   2 Tue Dec 7 07:43:24 2026 failed kong-3.4.1 3.14 Upgrade "<kong-app-name>" failed: <reason>
   ```

2. Rollback to revision 1:

   ```bash
   helm rollback <kong-app-name> 1
   ```

   ```bash
   helm -n <kong-namespace> history <kong-app-name>
   ```

   ```
   REVISION UPDATED STATUS CHART APP VERSION DESCRIPTION
   1 Tue Dec 7 07:16:48 2026 superseded kong-3.4.1 3.14 Install complete
   2 Tue Dec 7 07:43:24 2026 failed kong-3.4.1 3.14 Upgrade "<kong-app-name>" failed: <reason>
   3 Tue Dec 7 07:52:27 2026 deployed kong-3.4.1 3.14 Rollback to 1
   ```

For more details please check the Helm documentation.

If you edited the deployment, just edit it again and configure the value that was there before, e.g. `name: kong-enterprise-license`.

Related documentation

- Install on Kubernetes with Helm
- Kong Gateway Licensing
