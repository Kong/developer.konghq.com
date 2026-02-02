---
title: "{{site.mesh_product_name}} data plane on Kubernetes"
description: Configure data plane proxies on Kubernetes with automatic sidecar injection, tag generation, and custom container settings.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - data-plane
  - kubernetes

related_resources:
  - text: Deploy {{ site.mesh_product_name }} on Kubernetes
    url: /mesh/kubernetes/
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'
  - text: 'Zone ingress'
    url: /mesh/zone-ingress/
  - text: "Data plane proxy"
    url: /mesh/data-plane-proxy/
  - text: "Data plane on Universal"
    url: /mesh/data-plane-universal/
  - text: Configure data plane proxy membership
    url: /mesh/configure-data-plane-proxy-membership/
---

In {{site.mesh_product_name}}, data planes manage traffic between services using [data plane proxies](/mesh/data-plane-proxy/) (also known as sidecars on Kubernetes). The data plane proxies use the [`Dataplane`](/mesh/data-plane-proxy/#dataplane-entity) entity to manage the data plane configuration.

On Kubernetes, the {{ site.mesh_product_name }} control plane injects a `kuma-sidecar` container into your Pod's container to join your Kubernetes services to the mesh. If you're not using the CNI, it also injects a `kuma-init` into `initContainers` to setup [transparent proxying](/mesh/transparent-proxying/).

The `Dataplane` entity is automatically created for you, and because transparent proxying is used to communicate between the Service and the sidecar, no code changes are required in your applications.

You can control whether {{site.mesh_product_name}} automatically injects the [data plane proxy](/mesh/concepts/#data-plane-proxy-sidecar) by labeling either the namespace or the Pod with `kuma.io/sidecar-injection=enabled`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kuma-example
  labels:
    # injects {{site.mesh_product_name}} sidecar into every Pod in that namespace
    kuma.io/sidecar-injection: enabled
```

If you want to exclude certain Pods from the mesh, you can opt out of data plane injection using the `kuma.io/sidecar-injection=disabled` label.

{:.warning}
> {% new_in 2.11%} You must label the namespace with `kuma.io/sidecar-injection=disabled`, and then label Pods that require sidecar injection with `kuma.io/sidecar-injection=enabled`. Labeling a specific Pod with `kuma.io/sidecar-injection=disabled` when the namespace is labeled with `kuma.io/sidecar-injection=enabled` will not prevent sidecar injection.

{:.info}
> Since {{ site.mesh_product_name }} 2.11, each namespace in the mesh must have the `kuma.io/sidecar-injection` label. 

Once your Pod is running you can see the data plane CRD that matches it using `kubectl`:

```shell
kubectl get dataplanes $POD_NAME
```

## Tag generation

When `Dataplane` entities are automatically created, all labels from the Pod are converted into `Dataplane` tags.
Labels with keys that contain `kuma.io/` are not converted because they are reserved for {{site.mesh_product_name}}.
The following tags are added automatically and cannot be overridden using Pod labels:

* `kuma.io/service`: Identifies the Service name based on a Service that selects a Pod. The format is `<name>_<namespace>_svc_<port>` where `<name>`, `<namespace>` and `<port>` are from the Kubernetes Service that is associated with this particular Pod. When a Pod is spawned and isn't associated with any Kubernetes Service resource, the data plane tag is `kuma.io/service: <name>_<namespace>_svc`, where `<name>` and`<namespace>` are extracted from the Pod resource metadata.
* `kuma.io/zone`: Identifies the zone name in a [multi-zone deployment](/mesh/mesh-multizone-service-deployment/).
* `kuma.io/protocol`: Identifies the protocol that was defined by the `appProtocol` field on the Service that selects the Pod.
* `k8s.kuma.io/namespace`: Identifies the Pod's namespace.
* `k8s.kuma.io/service-name`: Identifies the name of the Kubernetes Service that selects the Pod.
* `k8s.kuma.io/service-port`: Identifies the port of the Kubernetes Service that selects the Pod.

  {:.info}
  > * If a Kubernetes Service exposes more than one port, multiple inbounds will be generated, all with different `kuma.io/service` values.
  > * If a Pod is attached to more than one Kubernetes Service, multiple inbounds will also be generated.

{:.warning}
> {% new_in 2.13 %}**Namespace constraint**: All Pods in a Kubernetes namespace should belong to the same mesh to ensure proper workload resource generation. A single namespace can't contain Pods in multiple meshes because workload resources are mesh-scoped and use the `app.kubernetes.io/name` label, which can cause resource collisions.
> 
> If {{site.mesh_product_name}} detects Pods in multiple meshes within the same namespace, it skips workload generation and emits a warning event. For more details, see the [namespace constraint documentation](/mesh/mesh-multi-tenancy/#data-plane-proxies).

### Tag generation example

Here's a sample tag generation configuration:

```yaml
apiVersion: v1
kind: Pod
metadata: 
  name: my-app
  namespace: my-namespace
  labels:
    foo: bar
    app: my-app
spec:
  # ...
---
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: my-namespace
spec:
  selector:
    app: my-app
  type: ClusterIP
  ports:
    - name: port1
      protocol: TCP
      appProtocol: http
      port: 80
      targetPort: 8080
    - name: port2
      protocol: TCP
      appProtocol: grpc
      port: 1200
      targetPort: 8081
---
apiVersion: v1
kind: Service
metadata:
  name: my-other-service
  namespace: my-namespace
spec:
  selector:
    foo: bar 
  type: ClusterIP
  ports:
    - protocol: TCP
      appProtocol: http
      port: 81
      targetPort: 8080
```

The configuration above generates the following inbounds in your {{site.mesh_product_name}} data plane:

```yaml
...
inbound:
  - port: 8080
    tags:
      kuma.io/protocol: http
      kuma.io/service: my-service_my-namespace_svc_80
      k8s.kuma.io/service-name: my-service
      k8s.kuma.io/service-port: "80"
      k8s.kuma.io/namespace: my-namespace
      # Labels coming from your Pod
      app: my-app
      foo: bar
  - port: 8081
    tags:
      kuma.io/protocol: grpc
      kuma.io/service: my-service_my-namespace_svc_1200
      k8s.kuma.io/service-name: my-service
      k8s.kuma.io/service-port: "1200"
      k8s.kuma.io/namespace: my-namespace
      # Labels coming from your Pod
      app: my-app
      foo: bar
  - port: 8080
    tags:
      kuma.io/protocol: http
      kuma.io/service: my-other-service_my-namespace_svc_81
      k8s.kuma.io/service-name: my-other-service
      k8s.kuma.io/service-port: "81"
      k8s.kuma.io/namespace: my-namespace
      # Labels coming from your Pod
      app: my-app
      foo: bar
```

Notice how `kuma.io/service` is built on `<serviceName>_<namespace>_svc_<port>` and `kuma.io/protocol` is the `appProtocol` field of your Service entry.

## Capabilities

The sidecar doesn't need any [capabilities](https://kubernetes.io/docs/tasks/configure-Pod-container/security-context/#set-capabilities-for-a-container) and works with `drop: ["ALL"]`. You can use [`ContainerPatch`](#custom-container-configuration) to control capabilities for the sidecar.

## Lifecycle

If you're using Kubernetes 1.29 or later, you can use the `SidecarContainers` feature, which significantly improves lifecycle management. For more information about why you would want to use sidecar containers, see [Sidecar Containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/) in the Kubernetes documentation.

### Kubernetes sidecar containers

To use Kubernetes sidecar containers with {{ site.mesh_product_name }}, enable the `experimental.sidecarContainers`/`KUMA_EXPERIMENTAL_SIDECAR_CONTAINERS` option.

This feature supports adding the injected Kuma container to `initContainers` with `restartPolicy: Always`, which marks it as a sidecar container. Refer to the [Kubernetes docs](https://kubernetes.io/docs/concepts/workloads/Pods/sidecar-containers/) to learn more about how they work.

The following lifecycle subsections are irrelevant when using this feature.
When enabled, the ordering of the sidecar startup and shutdown is enforced by Kubernetes.

To use the mesh in an init container, ensure that it comes after `kuma-sidecar`.
{{ site.mesh_product_name }} injects its sidecar at the front of the list but can't guarantee that its webhook runs last.

Draining incoming connections gracefully is handled via a `preStop` hook on the `kuma-sidecar` container.

{:.info}
> If the `terminationGracePeriodSeconds` has elapsed, ordering and thus correct behavior of the sidecar is no longer guaranteed. The grace period should be set to long enough that your workload finishes shutdown before it elapses.

Your application should itself initiate graceful shutdown when it receives SIGTERM. 
Kubernetes works largely asynchronously, So if your application exits too quickly it's possible that requests are still routed to the Pod and fail. 
See this [learnk8s.io article](https://learnk8s.io/graceful-shutdown#how-to-gracefully-shut-down-Pods) to learn about this problem and potential solutions.

When your application receives SIGTERM, you may need to wait some time. 
This can either be done in the application itself or you can add a `preStop` command to your container:

```yaml
kind: Deployment
# ...
spec:
  template:
    spec:
      containers:
      - name: app-container
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sleep", "15"]
```

### Joining the mesh

On Kubernetes, a `Dataplane` resource is automatically created by kuma-cp. For each Pod with the sidecar-injection label, a new `Dataplane` resource is created.

To allow the data plane to join the mesh in a graceful way, you need to make sure the application is ready to serve traffic before it can be considered a valid traffic destination.

#### Init containers

Due to the way {{site.mesh_product_name}} implements transparent proxying and sidecars in Kubernetes, network calls from init containers while running a mesh can be a challenge.

When injecting init containers into a Pod via webhooks, such as the Vault init container, there is no guarantee of the order in which the init containers run.
The ordering of init containers also doesn't provide a solution when the {{site.mesh_product_name}} CNI is used, as traffic redirection to the sidecar occurs even before any init container runs.

To solve this issue, start the init container with a specific user ID and exclude specific ports from interception, and the port of DNS interception. 
Here is an example of annotations to enable HTTPS traffic for a container running as user id `1234`:

```yaml
apiVersion: v1
king: Deployment
metadata:
  name: my-deployment
spec:
  template:
    metadata:
      annotations:
        traffic.kuma.io/exclude-outbound-tcp-ports-for-uids: "443:1234"
        traffic.kuma.io/exclude-outbound-udp-ports-for-uids: "53:1234"
    spec:
      initContainers:
      - name: my-init-container
        ...
        securityContext:
          runAsUser: 1234
```

{:.warning}
> With network calls inside the mesh with mTLS enabled, using the init container is impossible because `kuma-dp` is responsible for encrypting the traffic and only runs after all init containers have exited.

### Waiting for the data plane to be ready

By default, containers start in arbitrary order, so an app container can start even though the sidecar container might not be ready to receive traffic.

Making initial requests, such as connecting to a database, can fail for a brief period after the Pod starts.

To mitigate this problem try setting:

* `runtime.kubernetes.injector.sidecarContainer.waitForDataplaneReady` to `true`, or
* <!-- vale off -->The [`kuma.io/wait-for-dataplane-ready`](/mesh/annotations/#kumaiowait-for-dataplane-ready)<!-- vale on --> annotation to `true`

With these, the app container waits for the data plane container to be ready to serve traffic.

{:.warning}
> The `waitForDataplaneReady` setting relies on the fact that defining a `postStart` hook causes Kubernetes to run containers sequentially based on their order of occurrence in the `containers` list.
> This isn't documented and could change in the future.
> It also depends on injecting the `kuma-sidecar` container as the first container in the Pod, which isn't guaranteed since other mutating webhooks can rearrange the containers.

### Leaving the mesh

To leave the mesh in a graceful shutdown, you need to remove the traffic destination from all the clients before shutting it down.

When the {{site.mesh_product_name}} sidecar receives a SIGTERM signal, it:

1. Starts draining Envoy listeners.
1. Waits the entire drain time.
1. Terminates.

While draining, Envoy can still accept connections, however:

* It is marked unhealthy on the Envoy Admin `/ready` endpoint.
* It sends `connection: close` for HTTP/1.1 requests and the `GOAWAY` frame for HTTP/2. This forces clients to close their connection and reconnect to the new instance.

Whenever a user or system deletes a Pod, Kubernetes does the following:

1. Marks the Pod as terminated.
1. Performs the following actions concurrently on every container:
    1. Executes any pre-stop hook, if defined.
    1. Sends a SIGTERM signal.
    1. Waits until the container is terminated for the maximum amount of graceful termination time (by default, this is 60 seconds).
    1. Sends a SIGKILL to the container.
1. Removes the Pod object from the system.

When a Pod is marked as terminated, the control plane marks the `Dataplane` object as unhealthy, which triggers a configuration update to all the clients to remove it as a destination.
This can take a couple of seconds depending on the size of the mesh, resources available to the control plane, XDS configuration interval, etc.

To learn how Kubernetes handles the Pod lifecycle, see the [Kubernetes docs](https://kubernetes.io/docs/concepts/workloads/Pods/Pod-lifecycle/#Pod-termination). 

If the application served by the {{site.mesh_product_name}} sidecar quits immediately after the SIGTERM signal, there is a high chance that clients will still try to send traffic to this destination. To mitigate this, you must either:

* Support graceful shutdown in the application. For example, the application should wait X seconds to exit after receiving the first SIGTERM signal.
* Add a pre-stop hook to postpone stopping the application container:

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: redis
  spec:
    template:
      spec:
        containers:
        - name: redis
          image: "redis"
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sleep", "15"]
  ```

When a Pod is deleted, its matching `Dataplane` resource is deleted as well. This is possible thanks to the
[owner reference](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/) set on the `Dataplane` resource.

## Custom container configuration

If you want to modify the default container configuration, you can use the `ContainerPatch` Kubernetes CRD. 
It allows configuration of both sidecar and init containers. 
`ContainerPatch` resources are namespace-scoped and can only be applied in a namespace where a {{site.mesh_product_name}} control plane is running.

In most cases you shouldn't need to override the sidecar and init container configurations. 
`ContainerPatch` is a feature which requires good understanding of both {{site.mesh_product_name}} and Kubernetes.

A `ContainerPatch` specification consists of the list of [JSON patch](https://datatracker.ietf.org/doc/html/rfc6902) strings that describe the modifications. See [the entire resource schema](#schema) for more information.

{:.warning}
> When using `ContainerPath`, every `value` field must be a string containing valid JSON.

### ContainerPath example

Here's a sample `ContainerPath` configuration:

```yaml
apiVersion: kuma.io/v1alpha1
kind: ContainerPatch
metadata:
  name: container-patch-1
  namespace: {{site.mesh_namespace}}
spec:
  sidecarPatch:
    - op: add
      path: /securityContext/privileged
      value: "true"
    - op: add
      path: /resources/requests/cpu
      value: '"100m"'
    - op: add
      path: /resources/limits
      value: '{
        "cpu": "500m",
        "memory": "256Mi"
      }'
  initPatch:
    - op: add
      path: /securityContext/seccompProfile
      value: '{
        "type": "RuntimeDefault"
      }'
```

The configuration above makes the following changes:

{% table %}
columns:
  - title: Old configuration
    key: old
  - title: New configuration
    key: new
rows:
  - old: |
      ```yaml
      securityContext:
        runAsGroup: 5678
        runAsUser: 5678
      ```
    new: |
      ```yaml
      securityContext:
        runAsGroup: 5678
        runAsUser: 5678
        privileged: true
      ```
  - old: |
      ```yaml
      securityContext:
        capabilities:
          add:
            - NET_ADMIN
            - NET_RAW
        runAsGroup: 0
        runAsUser: 0
      ```
    new: |
      ```yaml
      securityContext:
        capabilities:
          add:
            - NET_ADMIN
            - NET_RAW
        runAsGroup: 0
        runAsNonRoot: true
      ```
  - old: |
      ```yaml
      requests:
        cpu: 50m
      ```
    new: |
      ```yaml
      requests:
        cpu: 100m
      ```
  - old: |
      ```yaml
      limits:
        cpu: 1000m
        memory: 512Mi
      ```
    new: |
      ```yaml
      limits:
        cpu: 500m
        memory: 256Mi
      ```
{% endtable %}

### Workload matching

A `ContainerPatch` is matched to a Pod via a `kuma.io/container-patches` annotation on the workload. 
Each annotation may be an ordered list of `ContainerPatch` names, which will be applied in the order specified.

Here's a sample configuration:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: app-ns
  name: app-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-deployment
  template:
    metadata:
      labels:
        app: app-deployment
      annotations:
        kuma.io/container-patches: container-patch-1,container-patch-2
    spec: [...]
```

### Default patches

You can configure `kuma-cp` to apply the list of default patches for workloads that don't specify their own patches by modifying the `containerPatches` value from the `kuma-dp` configuration:

```yaml
[...]
runtime:
  kubernetes:
    injector:
      containerPatches: [ ]
[...]
```

{:.info}
> If you specify the list of default patches (i.e. `["default-patch-1", "default-patch-2]`) but your workload is annotated with its own list of patches (for example, `["Pod-patch-1", "Pod-patch-2]`) only the latter will be applied.

To install a control plane with environment variables, you can run:

```sh
kumactl install control-plane --env-var "KUMA_RUNTIME_KUBERNETES_INJECTOR_CONTAINER_PATCHES=patch1,patch2"
```

### Error modes and validation

When applying `ContainerPatch`, {{site.mesh_product_name}} validates that the rendered container spec meets the Kubernetes specification.
However, {{site.mesh_product_name}} doesn't validate that the configuration works.

If a workload refers to a `ContainerPatch` that doesn't exist, the injection will explicitly fail and log the failure.

## Direct access to services

On Kubernetes, by default:
* Data plane proxies communicate with each other by leveraging the `ClusterIP` address of the `Service` resources. 
* Any request made to another Service is automatically load-balanced client-side by the data plane proxy that originates the request (they are load balanced by the local Envoy proxy sidecar proxy).

There are situations where you may want to bypass the client-side load balancing and directly access services by using their IP address (for example, in the case of Prometheus scraping metrics from services by their individual IP address).

When an originating Service wants to directly consume other Services by their IP address, the originating Service's `Deployment` resource must include the following annotation:

```yaml
kuma.io/direct-access-services: Service1, Service2, ServiceN
```

The value is a comma separated list of {{site.mesh_product_name}} Services that will be consumed directly. For example:

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
        kuma.io/direct-access-services: "backend_example_svc_1234,backend_example_svc_1235"
    spec:
      containers:
        ...
```

{:.info}
> When using direct access with a [headless Service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services), the destination Service will be accessible at `{{site.mesh_product_name}}-service.pod-name.mesh`.

You can also use `*` to indicate direct access to every Service in the mesh:

```yaml
kuma.io/direct-access-services: *
```

{:.warning}
> * Using `*` to directly access every Service is a resource-intensive operation.
> * Accessing services by using `kuma.io/direct-access-services` annotation means any policies applied to the Service will not take effect.


## ContainerPatches schema

{% json_schema kuma.io_containerpatches type=crd %}
