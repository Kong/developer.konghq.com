---
title: "\"Cannot mkdir ...: Read-only file system\" error when deploying Kong with `readOnlyRootFilesystem: true`"
content_type: support
description: "Why Kong fails to start with a `Cannot mkdir ... Read-only file system` error when `readOnlyRootFilesystem: true` is set, and how to fix it by mounting `emptyDir` volumes for `/tmp` and `/kong_prefix`."
products:
  - kic
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I use `securityContext` `readOnlyRootFilesystem: true` when deploying Kong?
  a: |
    Kong needs write access to `/tmp` and `/kong_prefix`, which `readOnlyRootFilesystem: true` blocks. Mount `emptyDir` volumes for both paths — the current Kong Helm chart already does this by default (`tmpDir.sizeLimit`, `prefixDir.sizeLimit`), or add them manually in your deployment YAML if you're not using Helm.
related_resources:
  - text: Kong Helm chart values.yaml (tmpDir/prefixDir reference)
    url: https://github.com/Kong/charts/blob/main/charts/kong/values.yaml
---

## Problem

When we add the following `securityContext` to our deployment:

```yaml

securityContext:
  privileged: false
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

We are getting an error similar to:

```
Cannot mkdir /tmp/resty_ShqblLSVKd: Read-only file system
```

How do we fix this?

## Cause

Kong needs write privilege to the `/tmp` and `/kong_prefix` folders. When using `readOnlyRootFilesystem: true`, Kong is unable to write to these folders.

## Solution

To solve this issue we need to create `emptyDir` volumes for these two folders.

If you are using Helm to deploy Kong, the current Kong Helm chart already mounts dedicated `emptyDir` volumes at `/tmp` (`tmpDir.sizeLimit`, default `1Gi`) and `/kong_prefix/` (`prefixDir.sizeLimit`, default `256Mi`) on both the init container and the main proxy container by default — confirmed live via `helm template` on a current chart release. You can find the current chart's values reference in the chart's `values.yaml` (`tmpDir`/`prefixDir` keys); see related resources for the link.

If you use YAML files for deployment, you can create volumes and volumeMounts with `securityContext` similar to the example below. (You can also use Helm with the `--dry-run` flag to generate the YAML files for you.)

```yaml
    spec:
        securityContext:       
          allowPrivilegeEscalation: false
          privileged: false
          readOnlyRootFilesystem: true
        volumeMounts:
        - name: kong-prefix-dir
          mountPath: /kong_prefix/
        - name: kong-tmp
          mountPath: /tmp
      volumes:
        - name: kong-prefix-dir
          emptyDir: {}
        - name: kong-tmp
          emptyDir: {}
```

Now you should be able to start Kong with `readOnlyRootFilesystem: true`.
