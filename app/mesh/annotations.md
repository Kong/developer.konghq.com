---
title: Kubernetes annotations and labels for {{site.mesh_product_name}}
description: Reference for all Kubernetes annotations and labels available in {{site.mesh_product_name}}, including sidecar injection, mesh association, transparent proxy settings, and metrics configuration.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - kubernetes

related_resources:
  - text: Deploy {{site.mesh_product_name}} on Kubernetes
    url: /mesh/kubernetes/
  - text: Zone egress
    url: /mesh/zone-egress/
  - text: MeshMultiZoneService
    url: /mesh/meshmultizoneservice/
  - text: Resource sizing guidelines
    url: /mesh/resource-sizing-guidelines/
  - text: Version compatibility
    url: /mesh/version-compatibility/

min_version:
  mesh: '2.8'
---

This page provides a complete list of all the annotations and labels you can specify when you run {{site.mesh_product_name}} in Kubernetes mode.

## Labels

### `kuma.io/sidecar-injection`

Enable or disable sidecar injection.

Apply this label on the namespace to inject the sidecar in all Pods created in the namespace:

```yaml
apiVersion: v1
kind: Namespace
metadata:
 name: default
 labels:
   kuma.io/sidecar-injection: enabled
[...]
```

{:.info}
> Since {{ site.mesh_product_name }} 2.11, each namespace in the mesh must have the `kuma.io/sidecar-injection` label.

Apply this label on a deployment using a Pod template to inject the sidecar in all Pods managed by this deployment:

```yaml
apiVersion: v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  template:
    metadata:
      labels:
        kuma.io/sidecar-injection: enabled
[...]
```

### `kuma.io/mesh`

Associate Pods with a particular mesh. The label value must be the name of a `Mesh` resource.

Apply the label on an entire namespace:

```yaml
apiVersion: v1
kind: Namespace
metadata:
 name: default
 labels:
   kuma.io/mesh: default
[...]
```

Apply the label on a Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: backend
 labels:
   kuma.io/mesh: default
[...]
```

Labeling pods or deployments will take precedence on the namespace annotation.

### `kuma.io/system-namespace`

This label is used to indicate the namespace in which {{site.mesh_product_name}} stores its secrets.
It's automatically set on the namespace in which the Helm chart is installed by a job started by Helm.

## Annotations

### `kuma.io/gateway`

Lets you specify the Pod should run in gateway mode. Inbound listeners are not generated.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway
spec:
  selector:
    matchLabels:
      app: gateway
  template:
    metadata:
      labels:
        app: gateway
      annotations:
        kuma.io/gateway: enabled
[...]
```

### `kuma.io/ingress`

Marks the Pod as the zone ingress. This is needed for multi-zone communication since it provides the entry point for traffic from other zones.

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: zone-ingress
 annotations:
   kuma.io/ingress: enabled
[...]
```

### `kuma.io/ingress-public-address`

Specifies the public address for an ingress. If it's not provided, {{site.mesh_product_name}} picks the address from the ingress Service.

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: zone-ingress
 annotations:
   kuma.io/ingress: enabled
   kuma.io/ingress-public-address: custom-address.com
[...]
```

### `kuma.io/ingress-public-port`

Specifies the public port for an ingress. If it's not provided, {{site.mesh_product_name}} picks the port from the ingress Service.

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: zone-ingress
 annotations:
   kuma.io/ingress: enabled
   kuma.io/ingress-public-port: "1234"
[...]
```

### `kuma.io/direct-access-services`

Defines a comma-separated list of Services that can be accessed directly.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/direct-access-services: test-app_playground_svc_80,test-app_playground_svc_443
    kuma.io/transparent-proxying: enabled
    kuma.io/transparent-proxying-inbound-port: [...]
    kuma.io/transparent-proxying-outbound-port: [...]
```

When you provide this annotation, {{site.mesh_product_name}} generates a listener for each IP address and redirects traffic through a `direct-access` cluster configured to encrypt connections.

These listeners are needed because transparent proxy and mTLS assume a single IP per cluster (for example, the ClusterIP of a Kubernetes Service). If you pass requests to direct IP addresses, Envoy considers them unknown destinations and manages them in passthrough mode, which means they're not encrypted with mTLS. The `direct-access` cluster enables encryption anyway.

{:.warning}
> You should specify this annotation only if you really need it. Generating listeners for every endpoint makes the xDS snapshot very large.

### `kuma.io/application-probe-proxy-port` {% new_in 2.9 %}

Specifies the port on which Application Probe Proxy listens. Application Probe Proxy coverts `HTTPGet`, `TCPSocket`, and `gRPC` probes in the Pod to `HTTPGet` probes and converts back to their original types before sending to the application when actual probe requests are received. 

Application Probe Proxy by default listens on port `9001` and it suppresses the virtual probes feature. By setting it to `0`, you can disable this feature and activate virtual probes, unless it's also disabled.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/application-probe-proxy-port: "9001"
[...]
```

### `kuma.io/virtual-probes`

Enables automatic converting of `HTTPGet` probes to virtual probes. The virtual probe is served on a sub-path of the insecure port specified with `kuma.io/virtual-probes-port`. For example, `:8080/health/readiness` points to `:9000/8080/health/readiness`, where `9000` is the value of the `kuma.io/virtual-probes-port` annotation.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/virtual-probes: enabled
    kuma.io/virtual-probes-port: "9000"
[...]
```

### `kuma.io/virtual-probes-port`

Specifies the insecure port for listening on virtual probes.

### `kuma.io/sidecar-env-vars`

Semicolon-separated list of environment variables for the {{site.mesh_product_name}} sidecar.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/sidecar-env-vars: TEST1=1;TEST2=2
```

### `kuma.io/container-patches`

Specifies the list of names of `ContainerPatch` resources to be applied on the `kuma-init` and `kuma-sidecar` containers.

It can be used on a resource describing a workload (`Deployment`, `DaemonSet`, or `Pod`):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: {{site.mesh_namespace}}
  name: example
spec:
  replicas: 1
  selector:
    matchLabels:
      app: example
  template:
    metadata:
      labels:
        app: example
      annotations:
        kuma.io/container-patches: container-patch-1,container-patch-2
    spec: [...]
```

For more information about how to use `ContainerPatch`, see [Custom container configuration](/mesh/data-plane-kubernetes/#custom-container-configuration).

### `prometheus.metrics.kuma.io/port`

Lets you override the mesh-wide default port that Prometheus should scrape metrics from.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    prometheus.metrics.kuma.io/port: "1234"
```

### `prometheus.metrics.kuma.io/path`

Lets you override the mesh-wide default path that Prometheus should scrape metrics from.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    prometheus.metrics.kuma.io/path: "/custom-metrics"
```

### `kuma.io/builtindns`

Tells the sidecar to use its builtin DNS server.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/builtindns: enabled
```

### `kuma.io/builtindnsport`

Port the builtin DNS server should listen on for DNS queries.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/builtindns: enabled
    kuma.io/builtindnsport: "15053"
```

### `kuma.io/ignore`

A boolean to mark a resource as ignored by {{site.mesh_product_name}}.
It currently only works for Services.
This is useful when transitioning to {{site.mesh_product_name}} or to temporarily ignore some entities.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: example
  annotations:
    kuma.io/ignore: "true"
```

### `traffic.kuma.io/exclude-inbound-ports`

List of inbound ports to exclude from traffic interception by the {{site.mesh_product_name}} sidecar.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    traffic.kuma.io/exclude-inbound-ports: "1234,1235"
```

### `traffic.kuma.io/exclude-outbound-ports`

List of outbound ports to exclude from traffic interception by the {{site.mesh_product_name}} sidecar.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    traffic.kuma.io/exclude-outbound-ports: "1234,1235"
```

### `kuma.io/transparent-proxying-experimental-engine`

Enable or disable the experimental transparent proxy engine on Pod.
The default value is `disabled`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/transparent-proxying-experimental-engine: enabled
```

### `kuma.io/envoy-admin-port`

Specifies the port for Envoy Admin API. If not set, the default admin port 9901 is used.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/envoy-admin-port: "8801"
```

### `kuma.io/envoy-log-level`

Specifies the log level for Envoy system logs to enable. The available log levels are `trace`, `debug`, `info`, `warning/warn`, `error`, `critical`, `off`. The default is `info`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/envoy-log-level: "warning"
```

### `kuma.io/envoy-component-log-level`

Specifies the log level for Envoy system logs to enable by components. See `ALL_LOGGER_IDS` in [logger.h](https://github.com/envoyproxy/envoy/blob/main/source/common/common/logger.h#L36) from the Envoy source code for a list of available components.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/envoy-component-log-level: "upstream:debug,connection:trace"
```

### `kuma.io/service-account-token-volume`

Volume (specified in the Pod spec) containing a Service account token for {{site.mesh_product_name}} to inject into the sidecar.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/service-account-token-volume: "token-vol"
spec:
  automountServiceAccountToken: false
  serviceAccount: example
  containers:
    - image: busybox
      name: busybox
  volumes:
    - name: token-vol
      projected:
        sources:
          - serviceAccountToken:
              expirationSeconds: 7200
              path: token
              audience: "https://kubernetes.default.svc"
          - configMap:
              items:
                - key: ca.crt
                  path: ca.crt
              name: kube-root-ca.crt
          - downwardAPI:
              items:
                - fieldRef:
                    apiVersion: v1
                    fieldPath: metadata.namespace
                  path: namespace
```

### `kuma.io/transparent-proxying-reachable-services`

A comma-separated list of `kuma.io/service`values to indicate which Services this resource communicates with.
For more information, see the [Reachable Services](/mesh/configure-transparent-proxying/#reachable-services).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  namespace: kuma-example
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        kuma.io/transparent-proxying-reachable-services: "redis_kuma-demo_svc_6379,elastic_kuma-demo_svc_9200"
    spec:
      containers:
        ...
```

### `kuma.io/transparent-proxying-ebpf`

When transparent proxy is installed with eBPF mode, you can disable it for particular workloads if necessary.

For more information, see [Transparent proxy with eBPF](/mesh/configure-transparent-proxying/#transparent-proxy-with-ebpf-experimental).


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  namespace: kuma-example
spec:
  [...]
  template:
    metadata:
      [...]
      annotations:
        kuma.io/transparent-proxying-ebpf: disabled
    spec:
      containers:
        [...]
```

### `kuma.io/transparent-proxying-ebpf-bpf-fs-path`

Path to the BPF FS if it's different from the default `/sys/fs/bpf` path.

For more information, see [Transparent proxy with eBPF](/mesh/configure-transparent-proxying/#transparent-proxy-with-ebpf-experimental).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  namespace: kuma-example
spec:
  [...]
  template:
    metadata:
      [...]
      annotations:
        kuma.io/transparent-proxying-ebpf-bpf-fs-path: /custom/bpffs/path
    spec:
      containers:
        [...]
```

### `kuma.io/transparent-proxying-ebpf-cgroup-path`

`cgroup2` path if it's different from the default `/sys/fs/cgroup` path.

For more information, see [Transparent proxy with eBPF](/mesh/configure-transparent-proxying/#transparent-proxy-with-ebpf-experimental).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  namespace: kuma-example
spec:
  [...]
  template:
    metadata:
      [...]
      annotations:
        kuma.io/transparent-proxying-ebpf-cgroup-path: /custom/cgroup2/path
    spec:
      containers:
        [...]
```

### `kuma.io/transparent-proxying-ebpf-programs-source-path`

Custom path for eBPF programs to be loaded when installing transparent proxy.

For more information, see [Transparent proxy with eBPF](/mesh/configure-transparent-proxying/#transparent-proxy-with-ebpf-experimental).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  namespace: kuma-example
spec:
  [...]
  template:
    metadata:
      [...]
      annotations:
        kuma.io/transparent-proxying-ebpf-programs-source-path: /custom/ebpf/programs/source/path
    spec:
      containers:
        [...]
```

### `kuma.io/transparent-proxying-ebpf-tc-attach-iface`

Name of the network interface that should be used to attach TC-related eBPF programs. 
By default, {{site.mesh_product_name}} uses the first non-loopback interface it finds.

For more information, see [Transparent proxy with eBPF](/mesh/configure-transparent-proxying/#transparent-proxy-with-ebpf-experimental).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-app
  namespace: kuma-example
spec:
  [...]
  template:
    metadata:
      [...]
      annotations:
        kuma.io/transparent-proxying-ebpf-tc-attach-iface: eth3
    spec:
      containers:
        [...]
```

### `kuma.io/wait-for-dataplane-ready`

Defines whether the sidecar container waits for the data plane to be ready before starting app container.
For more information, see [Data plane on Kubernetes](/mesh/data-plane-kubernetes/#waiting-for-the-data-plane-to-be-ready).

### `prometheus.metrics.kuma.io/aggregate-<name>-enabled`

Defines whether `kuma-dp` should scrape metrics from the application defined in the `Mesh` configuration. 
The default value is `true`. 

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    prometheus.metrics.kuma.io/aggregate-app-enabled: "false"
spec: ...
```

### `prometheus.metrics.kuma.io/aggregate-<name>-path`

Defines the path that the `kuma-dp` sidecar has to scrape for prometheus metrics. The default value is `/metrics`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    prometheus.metrics.kuma.io/aggregate-app-path: "/stats"
spec: ...
```

### `prometheus.metrics.kuma.io/aggregate-<name>-port`

Defines the port, that the `kuma-dp` sidecar has to scrape for prometheus metrics.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    prometheus.metrics.kuma.io/aggregate-app-port: "1234"
spec: ...
```

### `kuma.io/transparent-proxying-inbound-v6-port`

Defines the port to use for [IPv6](/mesh/ipv6-support/) traffic. To turn off IPv6, set this to 0.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/transparent-proxying-inbound-v6-port: "0"
spec: ...
```

### `kuma.io/sidecar-drain-time`

Allows specifying drain time of {{site.mesh_product_name}} data plane sidecar. The default value is 30s.
It can be changed using [the control plane configuration](/mesh/reference/kuma-cp/) or `KUMA_RUNTIME_KUBERNETES_INJECTOR_SIDECAR_CONTAINER_DRAIN_TIME` env.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/sidecar-drain-time: "10s"
spec: ...
```

### `kuma.io/init-first`

Allows specifying that the {{site.mesh_product_name}} init container should run first, ahead of any other init containers. 
The default is `false` if omitted. Setting this to `true` may be desirable for security, as it would prevent network access for other init containers. The order is not guaranteed, as other mutating admission webhooks may further manipulate this ordering.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example
  annotations:
    kuma.io/init-first: "true"
spec: ...
```
