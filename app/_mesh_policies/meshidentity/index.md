---
title: Mesh Identity
name: MeshIdentities
description: Define how workloads obtain cryptographic identity with MeshIdentity, supporting SPIFFE IDs and multiple certificate providers.
products:
  - mesh
content_type: plugin
type: policy
icon: policy.svg
tags:
  - certificates
  - security
  - mtls

min_version:
  mesh: '2.12'

related_resources:
  - text: Issuing Identity with MeshIdentity Spire provider
    url: /mesh/meshidentity-spire/
  - text: MeshService
    url: /mesh/meshservice/
  - text: MeshTLS
    url: /mesh/policies/meshtls/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
---

{:.warning}
> This resource is experimental.
> It works only on Kubernetes and requires [MeshService](/mesh/meshservice/) to be enabled.

`MeshIdentity` is a resource that defines how workloads in a mesh obtain their cryptographic identity.
It separates the responsibility of issuing identities from establishing trust,
enabling {{site.mesh_product_name}} to adopt [SPIFFE](https://spiffe.io/docs/latest/spiffe-about/overview/) compliant practices
while remaining flexible and easy to use.

With `MeshIdentity`, users can:

* Enable secure mTLS between services, using trusted certificate authorities.
* Switch identity providers without downtime, for example when migrating from built-in certificates to [Spire](https://spiffe.io/docs/latest/spire-about/).
* Assign different identity providers to subsets of workloads, allowing more granular control.

The following example shows the full structure:

{% policy_yaml %}
{% raw %}

```yaml
type: MeshIdentity
name: identity
mesh: default
spec:
  selector:
    dataplane:
      matchLabels: {}
  spiffeID:
    trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
    path: "/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}"
  provider:
    type: Bundled
    bundled:
      meshTrustCreation: Enabled
      insecureAllowSelfSigned: true
      certificateParameters:
        expiry: 24h
      autogenerate:
        enabled: true
```

{% endraw %}
{% endpolicy_yaml %}

## Configuration

`MeshIdentity` is a namespaced (system-namespace only) resource that controls how data plane proxies receive identity certificates.
It includes a few key fields that control how identities are issued and applied.
The following sections describe each field:

* [`selector`](#selector): Which data plane proxies this identity applies to.
* [`spiffeID`](#spiffeid): How the SPIFFE ID is constructed (trust domain and path).
* [`provider`](#provider): Which system issues the certificates (`Bundled` or `Spire`).

### Selector

The selector field controls which data plane proxies a `MeshIdentity` applies to.
It uses a Kubernetes-style label selector on data plane proxy tags.
You can scope an identity to all workloads, a subset of workloads, or none at all.

When multiple `MeshIdentity` resources apply to the same data plane proxy,
the one with the most specific selector (the greatest number of matching labels) takes precedence.
If two policies have selectors with the same number of labels, {{site.mesh_product_name}} compares their names lexicographically.
The policy whose name comes first in alphabetical order takes precedence.

#### Examples

The following table contains examples of the selector field with different scopes:

{% table %}
columns:
  - title: Description
    key: description
  - title: Example
    key: example
rows:
  - description: Apply to all data plane proxies
    example: |
      ```yaml
      spec:
        selector:
          dataplane:
            matchLabels: {}
      ```
  - description: Apply to a group of data plane proxies
    example: |
      ```yaml
      spec:
        selector:
          dataplane:
            matchLabels:
              app: my-app
      ```
  - description: Apply to nothing
    example: |
      ```yaml
      spec:
        selector: {}
      ```
{% endtable %}

### SPIFFE ID

The `spiffeID` field lets you override how SPIFFE IDs are constructed for the data plane proxies selected by this `MeshIdentity`.
By default, {{site.mesh_product_name}} generates a SPIFFE ID based on the mesh and zone.
With `spiffeID`, you can customize the `trustDomain` and the `path` template.

{% raw %}

```yaml
spec:
  spiffeID:
    trustDomain: "{{ .Mesh }}.{{ .Zone }}.mesh.local"
    path: "/ns/{{ .Namespace }}/sa/{{ .ServiceAccount }}"
```

{% endraw %}

Supported variables in `trustDomain` field are:

* `.Mesh`
* `.Zone`

Supported variables in `path` field are:

* `.Namespace`
* `.ServiceAccount`

You can also use resource `labels` in both `trustDomain` and `path`, for example:

{% raw %}

```yaml
spec:
  spiffeID:
    trustDomain: '{{ label "kuma.io/mesh" }}.{{ label "kuma.io/zone" }}.mesh.local'
    path: '/ns/{{ label "k8s.kuma.io/namespace" }}/sa/{{ label "k8s.kuma.io/service-account" }}'
```

{% endraw %}

#### Workload label requirement {% new_in 2.13 %}

When using {% raw %}`{{ label "kuma.io/workload" }}`{% endraw %} in the `path` template, data plane proxies selected by this `MeshIdentity` must have the `kuma.io/workload` label. This label can be provided either:

* Via a [data plane proxy token](/mesh/data-plane-proxy-authentication/#workload-label-in-tokens) generated with the `--workload` parameter
* Directly on the data plane proxy resource

Connections from data plane proxies lacking the required label will be rejected.

Here's an example using a workload label in the path:

{% raw %}

```yaml
spec:
  spiffeID:
    trustDomain: '{{ .Mesh }}.{{ .Zone }}.mesh.local'
    path: '/workload/{{ label "kuma.io/workload" }}'
```

{% endraw %}


### Provider

The `provider` field defines how identity certificates are issued.
This field is required and must specify one of the supported provider types:

* `Bundled`: Certificates are issued by {{site.mesh_product_name}}'s control plane, either autogenerated or supplied by the user.
* `Spire`: Certificates are issued directly by a SPIRE Agent through SDS.

