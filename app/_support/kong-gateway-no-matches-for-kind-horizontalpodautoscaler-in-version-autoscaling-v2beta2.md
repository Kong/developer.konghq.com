---
title: "`no matches for kind \"HorizontalPodAutoscaler\" in version \"autoscaling/v2beta2\"` error during a Helm upgrade after upgrading Kubernetes to 1.26"
content_type: support
description: "A Helm upgrade of the Kong deployment fails with `no matches for kind \"HorizontalPodAutoscaler\" in version \"autoscaling/v2beta2\"` after upgrading Kubernetes to 1.26, because that API version was removed. Fix it by editing the stored Helm release Secret or ConfigMap to reference `autoscaling/v2` instead."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: "Why does a Helm upgrade of the Kong deployment fail with \"no matches for kind 'HorizontalPodAutoscaler' in version 'autoscaling/v2beta2'\" after upgrading Kubernetes?"
  a: |
    Kubernetes 1.26 removed the `autoscaling/v2beta2` API, so a Helm release created with an older Kong chart still references it in the stored release Secret or ConfigMap, causing subsequent Helm upgrades to fail. Fix it by decoding the stored release object, replacing `v2beta2` with `v2`, re-encoding it, and patching it back onto the Secret or ConfigMap before retrying the Helm upgrade.
---

## Problem

We have recently upgraded our Kubernetes cluster to 1.26.

We are now receiving the following error when attempting helm upgrades on the Kong deployment and the upgrade fails:

```

Error: unable to build kubernetes objects from current release manifest: resource mapping not found for name: "kong" namespace: "kong" from "": no matches for kind "HorizontalPodAutoscaler" in version "autoscaling/v2beta2"
```

## Solution

This issue occurs because `autoscaling/v2beta2` has been removed as of Kubernetes version 1.26. Possibly due to using an outdated Helm chart to install Kong, your helm release secret/configmap (where the current configuration from your helm deployment is stored) still has an entry for `autoscaling/v2beta2`.

In order to remedy this we need to take the following steps:

- Get the name of the Secret or Configmap associated with the latest deployed release:
   - Secrets backend: `kubectl get secret -l owner=helm,status=deployed,name=<release_name> --namespace <release_namespace> | awk '{print $1}' | grep -v NAME`
   - ConfigMap backend: `kubectl get configmap -l owner=helm,status=deployed,name=<release_name> --namespace <release_namespace> | awk '{print $1}' | grep -v NAME`
- Get latest deployed release details:
   - Secrets backend: `kubectl get secret <release_secret_name> -n <release_namespace> -o yaml > release.yaml`
   - ConfigMap backend: `kubectl get configmap <release_configmap_name> -n <release_namespace> -o yaml > release.yaml`
- Backup the release in case you need to restore if something goes wrong:
   - `cp release.yaml release.bak`
   - In case of emergency, restore: `kubectl apply -f release.bak -n <release_namespace>`
- Decode the release object:
   - Secrets backend: `cat release.yaml | grep -oP '(?<=release: ).*' | base64 -d | base64 -d | gzip -d > release.data.decoded`
   - ConfigMap backend: `cat release.yaml | grep -oP '(?<=release: ).*' | base64 -d | gzip -d > release.data.decoded`
- Open the decoded object in a text editor (we recommend Visual Studio Code), CTRL-F for `v2beta2` and change this to `v2`
- Encode the edited release object:
   - Secrets backend: `cat release.data.decoded | gzip | base64 | base64`
   - ConfigMap backend: `cat release.data.decoded | gzip | base64`
- Create a patch.json file locally with the following fields:

```json

{
  "data": {
    "release": "YOUR_NEW_ENCODED_RELEASE_DATA"
  }
}
```

Ensure that there are no whitespaces or line breaks in the encoded release object (many text editors/linux shells will add line breaks)

- Apply the patch to your secret with the following command:

```bash

kubectl patch secret <secret_name> -n <secret_namespace> --patch-file=patch.json
```

You should now be able to helm upgrade normally.
