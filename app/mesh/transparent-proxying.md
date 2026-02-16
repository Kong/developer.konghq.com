---
title: Transparent proxying with {{site.mesh_product_name}}
description: Explains how transparent proxying in {{site.mesh_product_name}} works using iptables, including inbound and outbound traffic flow with Envoy.

content_type: reference
layout: reference

products:
  - mesh
breadcrumbs:
  - /mesh/

related_resources:
  - text: Multi-zone deployment
    url: /mesh/mesh-multizone-service-deployment/
  - text: Service discovery
    url: /mesh/service-discovery/
---

A transparent proxy is a type of server that can intercept network traffic to and from a service without changes to the client application code. In the case of {{site.mesh_product_name}} it is used to capture traffic and redirect it to a data plane to apply policies.

{{site.mesh_product_name}} uses [`iptables`](https://linux.die.net/man/8/iptables) and offers additional, experimental support for [`eBPF`](/mesh/cni/#merbridge-cni-with-ebpf).

Here's a high level visualization of how transparent proxying works:

<!-- vale off -->
{% mermaid %}
 sequenceDiagram
 autonumber
     participant Browser as client<br>(Mobile app)
     participant Kernel as Kernel
     participant ServiceMeshIn as kuma sidecar(15006)
     participant Node as example.com:5000<br>(Front-end app)
     participant ServiceMeshOut as kuma sidecar(15001)
     Browser->>+Kernel: GET / HTTP1.1<br>Host: example.com:5000
 
     rect rgb(233,233,233)
     Note over Kernel,ServiceMeshOut: EXAMPLE.COM
     Note over Node: (Optional)<br> Apply inbound policies
     Note over ServiceMeshOut: (Optional)<br> Apply inbound policies
     Kernel->>+ServiceMeshIn: Capture inbound TCP traffic<br>and redirect to the sidecar<br> (listener port 15006)
     ServiceMeshIn->>+Node: Redirect to the<br>original destination <br>(example.com:5000)
         Node->>+Kernel: Send the <br>front-end response
     Kernel->>+ServiceMeshOut: Capture outbound TCP traffic<br>and Redirect to the sidecar<br> (listener port 15001)
     end
     ServiceMeshOut->>+Browser: Response to client
{% endmermaid %}
<!-- vale on -->

If you choose to not use transparent proxying, or if you're running on a platform where transparent proxying isn't available, there are some additional consideration:

* You need to specify inbound and outbound ports on which you want to capture traffic
* `.mesh` addresses are unavailable
* You may need to update your application code to use the new capture ports
* There is no support for a VirtualOutbound

Without manipulating `iptables` to redirect traffic you will need to explicitly tell `kuma-dp` where to listen to capture it. This can require changes to your application code.

The example below specifies that `kuma-dp` will listen on the address `10.119.249.39:15000`. 
This in turn creates an Envoy listener for the port. 
When consuming a service over this address, it will cause traffic to redirect to `127.0.0.1:5000 `where our app is running:

```yaml
  type: Dataplane
  mesh: default
  name: demo-app
  networking: 
    address: 10.119.249.39 
    inbound: 
      - port: 15000
        servicePort: 5000
        serviceAddress: 127.0.0.1
        tags: 
          kuma.io/service: app
          kuma.io/protocol: http
```

## Kubernetes

On Kubernetes, `kuma-dp` leverages transparent proxying automatically via `iptables` installed with the `kuma-init` container or the CNI.
All incoming and outgoing traffic is automatically intercepted by `kuma-dp` without having to change the application code.

{{site.mesh_product_name}} integrates with the service naming provided by Kubernetes DNS, and also provides its own [{{site.mesh_product_name}} DNS](/mesh/dns/) for multi-zone service naming.

## Universal

On Universal, `kuma-dp` leverages the [data plane proxy specification](/mesh/data-plane-universal/#dataplane-resource-configuration) for receiving incoming requests on a pre-defined port.

In order to enable transparent proxying, the zone control plane must exist on a separate server. 
Running the zone control plane with PostgreSQL doesn't work with transparent proxying on the same machine.

There are several advantages when using transparent proxying in Universal mode:

* Simpler `Dataplane` resource, since you can omit the `outbound` section.
* Universal service naming with the `.mesh` [DNS domain](/mesh/dns) instead of explicit outbounds like `https://localhost:10001`.
* Better service manageability (security, tracing).

{:.info}
> If you run `firewalld` to manage firewalls and wrap `iptables`, add the `--store-firewalld` flag to `kumactl install transparent-proxy`. This persists the relevant rules across host restarts. The changes are stored in `/etc/firewalld/direct.xml`. There is no uninstall command for this feature.

### Configuring transparent proxying on Universal

To configure transparent proxying in Universal mode, you must first:

* Install `kuma-dp`, `envoy`, and `coredns` on the node that runs your service mesh workload.
* Set `coredns` in the path so that `kuma-dp` can access it. You can also set the location with the `--dns-coredns-path` flag in the `kuma-dp` command.

#### Configuring the service host

{{site.mesh_product_name}} comes with [`kumactl` executable](/mesh/cli/#kumactl), which can help you prepare the host for transparent proxying. 

{:.info}
> Due to the wide variety of Linux setup options, these steps may vary and may need to be adjusted for the specifics of the particular deployment.

The host that will run the `kuma-dp` process in transparent proxying mode needs to be prepared with the following steps, executed as `root`:

1. Create a new dedicated user on the machine.

   ```sh
   useradd -u 5678 -U kuma-dp
   ```

1. Redirect all the relevant inbound, outbound and DNS traffic to the {{site.mesh_product_name}} data plane proxy:

   ```sh
   kumactl install transparent-proxy \
     --kuma-dp-user kuma-dp \
     --redirect-dns \
     --exclude-inbound-ports 22
   ```

   If you're running any other services on that machine, adjust the comma separated lists of `--exclude-inbound-ports` and `--exclude-outbound-ports` accordingly.

   {:.danger}
   > This command **will change** the host's `iptables` rules.

   {:.info}
   > The changes won't persist over restarts. You must either add this command to your start scripts or use `firewalld`.

#### Configuring the Dataplane resource

In transparent proxying mode, the `Dataplane` resource should omit the `networking.outbound` section and use `networking.transparentProxying` section instead:

```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
  - port: {% raw %}{{ port }}{% endraw %}
    tags:
      kuma.io/service: demo-client
  transparentProxying:
    redirectPortInbound: 15006
    redirectPortOutbound: 15001
```

The ports used above are the default ones that `kumactl install transparent-proxy` will set. These can be changed using the relevant flags to that command.

#### Invoking the {{site.mesh_product_name}} data plane

{:.warning}
> It's' important that the `kuma-dp` process runs with the same system user that was passed to `kumactl install transparent-proxy --kuma-dp-user`.
> The service itself should run with any other user than `kuma-dp`. Otherwise, it won't be able to leverage transparent proxying.

When using `systemd`, you can invoke the data plane with a `User=kuma-dp` entry in the `[Service]` section of the service file.

When starting `kuma-dp` with a script or some other automation, you can use `runuser`:

```sh
runuser -u kuma-dp -- \
  /usr/bin/kuma-dp run \
    --cp-address=https://$CONTROL_PLANE_HOST:5678 \
    --dataplane-token-file=$TOKEN_FILEPATH \
    --dataplane-file=$DATAPLANE_CONFIG_FILE \
    --dataplane-var name=dp-demo \
    --dataplane-var address=$VM_IP \
    --dataplane-var port=$SERVICE_PORT  \
    --binary-path /usr/local/bin/envoy
```

Once this is configured, you'll be able to reach the Service on the same IP and port as before installing transparent proxy, but the traffic will go through Envoy. You can also connect to Services using [{{site.mesh_product_name}} DNS](/mesh/dns/).

### Upgrades

Before upgrading to the next version of {{site.mesh_product_name}}, we recommend uninstalling the transparent proxy before replacing the `kumactl` binary:

```sh
kumactl uninstall transparent-proxy
```

## Configuration

### Intercepted traffic

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}


On Kubernetes, by default, all traffic is intercepted by Envoy. You can exclude certain ports from being intercepted by Envoy with the following annotations on the Pod:

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
        # all incoming connections on ports 1234 won't be intercepted by Envoy
        traffic.kuma.io/exclude-inbound-ports: "1234"
        # all outgoing connections on ports 5678, 8900 won't be intercepted by Envoy
        traffic.kuma.io/exclude-outbound-ports: "5678,8900"
    spec:
      containers:
        ...
```  

You can exclude ports on a whole {{site.mesh_product_name}} deployment with the following {{site.mesh_product_name}} [control plane configuration](/mesh/control-plane-configuration/):
```sh
KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_INBOUND_PORTS=1234
KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_OUTBOUND_PORTS=5678,8900
```
{% endnavtab %}

{% navtab "Universal" %}

On Universal, by default, all ports are intercepted by the transparent proxy. This may prevent remote access to the host via SSH or other management tools when `kuma-dp` is not running.

If you need to access the host directly, even when `kuma-dp` is not running, use the `--exclude-inbound-ports` flag with `kumactl install transparent-proxy` to specify a comma-separated list of ports to exclude from redirection.

Run `kumactl install transparent-proxy --help` for all available options.
{% endnavtab %}
{% endnavtabs %}

### Reachable Services

By default, every data plane proxy in the mesh follows every other data plane proxy.
This may lead to performance problems in larger deployments of the mesh.
We recommend defining a list of Services that your Service connects to.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
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
        # a comma separated list of kuma.io/service values
        kuma.io/transparent-proxying-reachable-services: "redis_kong-mesh-demo_svc_6379,elastic_kong-mesh-demo_svc_9200"
    spec:
      containers:
        ...
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
  - port: {% raw %}{{ port }}{% endraw %}
    tags:
      kuma.io/service: demo-client
  transparentProxying:
    redirectPortInbound: 15006
    redirectPortOutbound: 15001
    reachableServices:
      - redis_kong-mesh-demo_svc_6379
      - elastic_kong-mesh-demo_svc_9200 
```
{% endnavtab %}
{% endnavtabs %}

### Reachable backends {% new_in 2.9 %}

The reachable backends feature provides similar functionality to [reachable services](#reachable-services), but it applies to the [`MeshService`](/mesh/meshservice/), [`MeshExternalService`](/mesh/meshexternalservice/), and [`MeshMultiZoneService`](/mesh/meshmultizoneservice/) resources.

{:.warning}
> This feature works only when a `MeshService` is enabled.

By default, every data plane proxy in the mesh tracks every other data plane proxy. 
Configuring `reachableBackends` can improve performance and reduce resource use.

Unlike reachable services, the model for providing data in reachable backends is more structured.

#### Model

Reachable backends are configured using the following parameters:

- `refs`: A list of all resources your application should track and communicate with.
  - `kind`: The type of resource. Possible values include:
    - [`MeshService`](/mesh/meshservice/)
    - [`MeshExternalService`](/mesh/meshexternalservice/)
    - [`MeshMultiZoneService`](/mesh/meshmultizoneservice/)
  - `name`: The name of the resource.
  - `namespace`: The namespace where the resource is located. When this is defined, the name is required. This parameter is only used on Kubernetes.
  - `labels`: A list of labels to match the resources. Either `labels` or `name` can be defined.
  - `port`: (Optional) The port of the Service you want to communicate with. This works with `MeshService` and `MeshMultiZoneService`

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
...
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        kuma.io/reachable-backends: |
          refs:
          - kind: MeshService
            name: redis
            namespace: kong-mesh-demo
            port: 8080
          - kind: MeshMulitZoneService
            labels:
              kuma.io/display-name: test-server
          - kind: MeshExternalService
            name: mes-http
            namespace: kuma-system
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  ...
  transparentProxying:
    redirectPortInbound: 15006
    redirectPortOutbound: 15001
    reachableBackends:
      refs:
      - kind: MeshService
        name: redis
      - kind: MeshMulitZoneService
        labels:
          kuma.io/display-name: test-server
      - kind: MeshExternalService
        name: mes-http
```
{% endnavtab %}
{% endnavtabs %}

#### Examples

Here are some reachable backend configuration examples.

Configure a `demo-app` that communicates only with `redis` on port 6379:

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: kong-mesh-demo
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        kuma.io/reachable-backends: |
          refs:
          - kind: MeshService
            name: redis
            namespace: kong-mesh-demo
            port: 6379
    spec:
      containers:
        ...
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
  - port: {% raw %}{{ port }}{% endraw %}
    tags:
      kuma.io/service: demo-app
  transparentProxying:
    redirectPortInbound: 15006
    redirectPortOutbound: 15001
    reachableBackends:
      refs:
      - kind: MeshService
        name: redis
        port: 6379
```
{% endnavtab %}
{% endnavtabs %}

Configure a `demo-app` that doesn't need to communicate with any Service:

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: kong-mesh-demo
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        kuma.io/reachable-backends: ""
    spec:
      containers:
        ...
```
{% endnavtab %}
{% navtab "Universal" %}
```yaml
type: Dataplane
mesh: default
name: {% raw %}{{ name }}{% endraw %}
networking:
  address: {% raw %}{{ address }}{% endraw %}
  inbound:
  - port: {% raw %}{{ port }}{% endraw %}
    tags:
      kuma.io/service: demo-app
  transparentProxying:
    redirectPortInbound: 15006
    redirectPortOutbound: 15001
    reachableBackends: {}
```
{% endnavtab %}
{% endnavtabs %}

Configure a `demo-app` that communicates with all `MeshServices` in the `kong-mesh-demo` namespace:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: kong-mesh-demo
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        kuma.io/reachable-backends: |
          refs:
          - kind: MeshService
            labels:
              k8s.kuma.io/namespace: kong-mesh-demo
    spec:
      containers:
        ...
```

### Transparent Proxy with eBPF (experimental)

Starting from {{site.mesh_product_name}} 2.0 you can set up transparent proxy to use eBPF instead of `iptables`.

{:.warning}
> To use transparent proxying with eBPF, your environment must use version 5.7 of Kernel or higher and have `cgroup2` available.

{% navtabs "Environment" %}
{% navtab "Kubernetes" %}

```sh
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}experimental.ebpf.enabled=true" | kubectl apply -f-
```

{% endnavtab %}

{% navtab "Universal" %}

```sh
kumactl install transparent-proxy \
  --experimental-transparent-proxy-engine \
  --ebpf-enabled \
  --ebpf-instance-ip $IP_ADDRESS \
  --ebpf-programs-source-path $PATH
```

{:.info}
> If your environment contains more than one non-loopback network interface, and you want to specify explicitly which one should be used for transparent proxying, provide it using the `--ebpf-tc-attach-iface <IFACE_NAME>` flag during the transparent proxy installation.

{% endnavtab %}
{% endnavtabs %}

