---
title: Mesh resource
description: Reference for the Mesh resource, the root resource that defines service mesh instances with mTLS, networking, routing, and observability configuration.
content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - mtls
  - service-mesh

related_resources:
  - text: Configuring your mesh and multi-tenancy
    url: /mesh/mesh-multi-tenancy/
  - text: Mutual TLS
    url: /mesh/mutual-tls/
  - text: Data plane proxy membership
    url: /mesh/configure-data-plane-proxy-membership/
  - text: Non-mesh traffic
    url: /mesh/policies/meshpassthrough/
  - text: Zone Egress
    url: /mesh/zone-egress/
  - text: MeshService
    url: /mesh/meshservice/
---

The `Mesh` resource defines a service mesh instance. It is the parent resource of all other {{site.mesh_product_name}} resources, including [data plane proxies](/mesh/data-plane-proxy/) and [policies](/mesh/policies/).

Create multiple meshes to isolate services by team, environment, or security requirements. Each data plane proxy belongs to exactly one mesh.

{{site.mesh_product_name}} creates a `default` mesh automatically on startup. Disable this by setting `KUMA_DEFAULTS_SKIP_MESH_CREATION=true`.

{:.warning}
> **Kubernetes namespace constraint:** On Kubernetes, a single namespace cannot contain pods in multiple meshes. To prevent this, enable [`runtime.kubernetes.disallowMultipleMeshesPerNamespace`](/mesh/kuma-cp-reference/). See [namespace-mesh constraint](/mesh/mesh-multi-tenancy/#data-plane-proxies) for details.

## Spec fields

{% table %}
columns:
  - title: Field
    key: field
  - title: Description
    key: description
rows:
  - field: "`mtls`"
    description: "mTLS configuration with CA backends. See [Mutual TLS](/mesh/mutual-tls/)."
  - field: "`networking.outbound.passthrough`"
    description: "Allow traffic to unknown destinations. Default: `true`. See [Non-mesh traffic](/mesh/policies/meshpassthrough/)."
  - field: "`routing.zoneEgress`"
    description: "Route cross-zone/external traffic through ZoneEgress. See [Zone Egress](/mesh/zone-egress/)."
  - field: "`routing.localityAwareLoadBalancing`"
    description: "Prefer endpoints in same zone. See [MeshLoadBalancingStrategy](/mesh/policies/meshloadbalancingstrategy/)."
  - field: "`routing.defaultForbidMeshExternalServiceAccess`"
    description: "Block MeshExternalService traffic by default."
  - field: "`constraints.dataplaneProxy`"
    description: "Control which proxies can join mesh. See [DP membership](/mesh/configure-data-plane-proxy-membership/)."
  - field: "`skipCreatingInitialPolicies`"
    description: "Skip default policy creation. Use `['*']` to skip all."
  - field: "`meshServices.mode`"
    description: "MeshService generation: `Disabled`, `Everywhere`, `ReachableBackends`, `Exclusive`. See [MeshService](/mesh/meshservice/)."
{% endtable %}

{:.warning}
> When mTLS is enabled, all traffic is denied unless [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) allows it.

## Examples

### Basic mesh

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
```

{% endnavtab %}
{% endnavtabs %}

### Mesh with mTLS enabled (builtin CA)

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: builtin
        dpCert:
          rotation:
            expiration: 24h
        conf:
          caCert:
            RSAbits: 2048
            expiration: 10y
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin
      dpCert:
        rotation:
          expiration: 24h
      conf:
        caCert:
          RSAbits: 2048
          expiration: 10y
```

{% endnavtab %}
{% endnavtabs %}

### Mesh with mTLS (provided CA)

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: provided
        dpCert:
          rotation:
            expiration: 24h
        conf:
          cert:
            secret: my-ca-cert
          key:
            secret: my-ca-key
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: provided
      dpCert:
        rotation:
          expiration: 24h
      conf:
        cert:
          secret: my-ca-cert
        key:
          secret: my-ca-key
```

{% endnavtab %}
{% endnavtabs %}

### Mesh with permissive mTLS mode

Accept both mTLS and plaintext traffic (for migration):

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
      - name: ca-1
        type: builtin
        mode: PERMISSIVE
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin
      mode: PERMISSIVE
```

{% endnavtab %}
{% endnavtabs %}

{:.warning}
> PERMISSIVE mode is not secure. Use only during migration, then switch to STRICT.

### Mesh with ZoneEgress routing

Route cross-zone and external traffic through ZoneEgress:

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  routing:
    zoneEgress: true
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
routing:
  zoneEgress: true
```

{% endnavtab %}
{% endnavtabs %}

### Mesh with passthrough disabled

Block traffic to unknown destinations:

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  networking:
    outbound:
      passthrough: false
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
networking:
  outbound:
    passthrough: false
```

{% endnavtab %}
{% endnavtabs %}

### Mesh without default policies

Skip all default policy creation:

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  skipCreatingInitialPolicies: ['*']
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
skipCreatingInitialPolicies: ['*']
```

{% endnavtab %}
{% endnavtabs %}

### Mesh with namespace restrictions (Kubernetes)

Allow only pods from specific namespaces:

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  constraints:
    dataplaneProxy:
      requirements:
        - tags:
            k8s.kuma.io/namespace: team-a
        - tags:
            k8s.kuma.io/namespace: team-b
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
constraints:
  dataplaneProxy:
    requirements:
      - tags:
          k8s.kuma.io/namespace: team-a
      - tags:
          k8s.kuma.io/namespace: team-b
```

{% endnavtab %}
{% endnavtabs %}

### Mesh with zone segmentation

Restrict mesh to specific zones in multizone deployment:

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: production
spec:
  constraints:
    dataplaneProxy:
      requirements:
        - tags:
            kuma.io/zone: us-east
        - tags:
            kuma.io/zone: us-west
      restrictions:
        - tags:
            env: development
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: production
constraints:
  dataplaneProxy:
    requirements:
      - tags:
          kuma.io/zone: us-east
      - tags:
          kuma.io/zone: us-west
    restrictions:
      - tags:
          env: development
```

{% endnavtab %}
{% endnavtabs %}

### Mesh with MeshServices enabled

Enable automatic MeshService generation:

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  meshServices:
    mode: Exclusive
```

{% endnavtab %}
{% navtab "Universal" %}

```yaml
type: Mesh
name: default
meshServices:
  mode: Exclusive
```

{% endnavtab %}
{% endnavtabs %}

## All options

{% schema_viewer Mesh type=proto %}
