---
title: MeshTrafficPermission with SPIFFE ID matchers
name: MeshTrafficPermissions
description: Control service-to-service access using SPIFFE identities with allow, deny, and shadow deny rules.
products:
  - mesh
content_type: plugin
type: policy
icon: policy.svg
tags:
  - access-control
  - authorization
  - security
min_version:
  mesh: '2.12'
related_resources:
  - text: Issue identity with the MeshIdentity bundled provider
    url: /mesh/issue-identity-with-meshidentity/
  - text: Issue identity with MeshIdentity Spire provider
    url: /mesh/issue-identity-with-meshidentity-spire/
  - text: MeshIdentity policy
    url: /mesh/policies/meshidentity/
  - text: MeshTrust policy
    url: /mesh/policies/meshtrust/
  - text: MeshTLS policy
    url: /mesh/policies/meshtls/
---

{:.warning}
> This resource is experimental.
> Enable [MeshIdentity](/mesh/policies/meshidentity/) before you apply `MeshTrafficPermission`.

## Overview

`MeshTrafficPermission` defines which clients can access services inside a mesh based on their SPIFFE identities.
If no `MeshTrafficPermission` applies, the default behavior is to deny all requests.

You can use `MeshTrafficPermission` to:

* deny requests from specific clients or namespaces so service owners cannot override that deny rule
* allow groups of clients, such as all workloads in a namespace, to access services by default
* shadow-deny traffic so you can validate a policy before you enforce it

The following example shows a common rule set:

{% policy_yaml namespace=kuma-demo %}

```yaml
type: MeshTrafficPermission
name: my-app-permissions
mesh: my-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: my-app
  rules:
    - default:
        deny:
          - spiffeID:
              type: Prefix
              value: "spiffe://my-mesh.us-east-2.mesh.local/ns/legacy-ns"
          - spiffeID:
              type: Exact
              value: "spiffe://my-mesh.us-east-2.mesh.local/ns/test/sa/client"
        allow:
          - spiffeID:
              type: Prefix
              value: "spiffe://my-mesh.us-east-2.mesh.local"
```

{% endpolicy_yaml %}

With this policy in place, workloads labeled `app: my-app` reject connections from identities in the `legacy-ns` namespace
and from the specific `test/client` identity, while continuing to accept other identities in the `my-mesh.us-east-2.mesh.local`
[trust domain](/mesh/policies/meshtrust/).

## Configuration

`MeshTrafficPermission` uses three matcher lists:

* `deny`: Clients that must always be denied
* `allow`: Clients that are explicitly allowed
* `allowWithShadowDeny`: Clients that are allowed, but also logged as if they were denied

`allowWithShadowDeny` helps you test a new policy before you enforce a deny rule.

Requests are evaluated in this order:

1. If a request matches at least one `deny` matcher, the result is `DENY`.
1. Otherwise, if a request matches at least one `allow` or `allowWithShadowDeny` matcher, the result is `ALLOW`.
1. If no matcher applies, the result is `DENY`.

See the **Examples** tab for ready-to-apply policies that deny namespace-wide traffic,
allow namespace-wide traffic, and override a mesh-wide allow rule on a specific service port.
Use the **Configuration reference** tab for the complete schema.
