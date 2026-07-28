---
title: Kong Mesh - How to set `securityContext` `runAsUser`/`runAsGroup` to 10001 on the sidecar
content_type: support
description: "This can't be done via `containerPatches` because the UID needs to be specified to have it ignored by iptables."
products:
  - mesh
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Reference
    url: "/mesh/reference/kuma-cp/#:~:text=KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_UID"
tldr:
  q: How do I set `securityContext` `runAsUser`/`runAsGroup` to 10001 on the Kong Mesh sidecar?
  a: |
    You can't do this with `containerPatches` because the UID needs to be specified so iptables can ignore it. Instead, set `KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_UID` and `KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_GUI` as environment variables on your Kong Mesh installation.
---

## Problem

We have a security requirement to set `runAsUser` and `runAsGroup` to a specific ID, i.e.: 10001, inside Kong Mesh. We are trying to apply a container Patch to accomplish this but it is resulting in the following error:

```
"Error: Failed to generate Envoy bootstrap config. context canceled"
```

How can we resolve this and add the `securityContext` required?

## Cause

This can't be done via `containerPatches` because the UID needs to be specified to have it ignored by iptables.

## Solution

To have this done successfully we need to add the following environment variables to your Mesh Install.

```yaml
      envVars:
        KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_UID: 10001
        KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_GUI: 10001
```

Once this is done, deploy your Kong Mesh and we can verify it deployed successfully with the following command:

```bash
k get po -n kuma-demo <pod> -o yaml | grep -i "security" -A5

securityContext:
runAsGroup: 10001
runAsUser: 10001
```
</content>
