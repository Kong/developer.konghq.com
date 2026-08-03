---
title: "Removing the `x-forwarded-client-cert` header from outbound requests in a Kong Mesh environment"
content_type: support
description: "Use a `MeshProxyPatch` to set `forwardClientCertDetails` to `SANITIZE`, which strips the `x-forwarded-client-cert` header from outbound requests in a Kong Mesh environment."
products:
  - mesh
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: "How can I remove the `x-forwarded-client-cert` header from all outbound requests in a Kong Mesh environment?"
  a: |
    Apply a `MeshProxyPatch` that sets `forwardClientCertDetails` to `SANITIZE` on the HTTP connection manager. This strips the `x-forwarded-client-cert` header from outbound traffic at the mesh level.
---

## Overview

How can I remove the `x-forwarded-client-cert` header from all outbound requests in a Kong Mesh environment?

## Steps

The resolution involves using a `MeshProxyPatch` to modify the Envoy configuration at the mesh level. The `MeshProxyPatch` resource was introduced in version 2.2.0. The patch modifies the `HttpConnectionManager` to change the `forwardClientCertDetails` setting to `SANITIZE`, which prevents the `x-forwarded-client-cert` header from being forwarded.

Here is the `MeshProxyPatch` configuration that resolved the issue:

```yaml

    apiVersion: kuma.io/v1alpha1
    kind: MeshProxyPatch
    metadata:
      name: remove-client-cert-details
      namespace: kong-mesh-system
    spec:
      targetRef:
        kind: Mesh
      default:
        appendModifications:
          - networkFilter:
              operation: Patch
              match:
                name: envoy.filters.network.http_connection_manager
                origin: inbound
              jsonPatches:
              - op: replace
                path: /forwardClientCertDetails
                value: SANITIZE
```

Additional tips

- Ensure that the Kong Mesh version you are using supports the `MeshProxyPatch` resource. This feature is available from version 2.2.0 onwards.

- After applying the `MeshProxyPatch`, verify that the changes have been propagated to the data planes by inspecting the sidecar configuration dump (accessible at `:9901/config_dump` on the sidecar admin interface).

- If you encounter issues or the header is still present, check the control plane and sidecar logs for any errors or warnings that might indicate why the patch is not being applied as expected.

- Remember to replace the placeholder values in the configuration with the actual values relevant to your environment, such as the mesh name and namespace.
