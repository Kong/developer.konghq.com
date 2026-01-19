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
  - text: Configure transparent proxying
    url: /how-to/configure-transparent-proxying/
  - text: Multi-zone deployment
    url: /mesh/mesh-multizone-service-deployment/
  - text: Mesh service discovery
    url: /mesh/service-discovery/
---

A transparent proxy is a type of server that can intercept network traffic to and from a service without changes to the client application code. In the case of {{site.mesh_product_name}} it is used to capture traffic and redirect it to `kuma-dp` so Mesh policies can be applied.

To accomplish this, {{site.mesh_product_name}} utilizes [`iptables`](https://linux.die.net/man/8/iptables) and offers additional, experimental support for [`eBPF`](/docs/{{ page.release }}/production/dp-config/cni/#merbridge-cni-with-ebpf). The examples provided in this section will concentrate on iptables to clearly illustrate the point.

Below is a high level visualization of how Transparent Proxying works

{% mermaid %}
 sequenceDiagram
 autonumber
     participant Browser as Client<br>(e.g. mobile app)
     participant Kernel as Kernel
     participant ServiceMeshIn as kuma sidecar(15006)
     participant Node as example.com:5000<br>(Front-end App)
     participant ServiceMeshOut as kuma sidecar(15001)
     Browser->>+Kernel: GET / HTTP1.1<br>Host: example.com:5000
 
     rect rgb(233,233,233)
     Note over Kernel,ServiceMeshOut: EXAMPLE.COM
     Note over Node: (Optional)<br> Apply inbound policies
     Note over ServiceMeshOut: (Optional)<br> Apply inbound policies
     Kernel->>+ServiceMeshIn: Capture inbound TCP traffic<br>and Redirect to the sidecar<br> (listener port 15006)
     ServiceMeshIn->>+Node: Redirect to the<br>original destination <br>(example.com:5000)
         Node->>+Kernel: Send the <br>Front-end Response
     Kernel->>+ServiceMeshOut: Capture outbound TCP traffic<br>and Redirect to the sidecar<br> (listener port 15001)
     end
     ServiceMeshOut->>+Browser: Response to Client
     %% Note over Browser,ServiceMeshOut: Traffic Flow Sequence
{% endmermaid %}

If you choose to not use transparent proxying, or you are running on a platform where transparent proxying is not available, there are some additional considerations.

- You will need to specify inbound and outbound ports to capture traffic on
- .mesh addresses are unavailable
- You may need to update your application code to use the new capture ports
- No support for a VirtualOutbound

Without manipulating IPTables to redirect traffic you will need to explicitly tell `kuma-dp` where to listen to capture it. As noted, this can require changes to your application code as seen below:

Here we specify that we will listen on the address 10.119.249.39:15000 (line 7). This in turn creates an envoy listener for the port. When consuming a service over this 15000 it will cause traffic to redirect to 127.0.0.1:5000 (line 8) where our app is running. 

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

## How it works

### Inbound TCP Traffic
The inbound port, 15006, is the default for capturing requests to the system. This rule allows us to capture and redirect ALL TCP traffic to port 15006. 
```
--append KUMA_MESH_INBOUND_REDIRECT --protocol tcp --jump REDIRECT --to-ports 15006
```

An envoy listener is also created for this port which we can see in the admin interface (:9901/config_dump). In the below example you can see the listener created on all interfaces (line 8) and port 15006 (line 9).

```json
     "name": "inbound:passthrough:ipv4",
     "active_state": {
      "listener": {
       "@type": "type.googleapis.com/envoy.config.listener.v3.Listener",
       "name": "inbound:passthrough:ipv4",
       "address": {
        "socket_address": {
         "address": "0.0.0.0",
         "port_value": 15006
        }
       },
      ...
       "use_original_dst": true,
       "traffic_direction": "INBOUND",
```

Notice the setting [use_original_dst](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener.proto) (line 13). This listener will send traffic to a special type of cluster, ORIGINAL_DST. This is important since we are redirecting traffic here based on the IPtables rules, which means when this service was requested it was not likely it was requested over this port, 15006, but rather whatever the target application is listening on (i.e. demo-app port 5000)

```json
     "name": "inbound:10.244.0.6:5000",
     "active_state": {
      "version_info": "9dac7d53-3560-4ad4-ba42-c7e563db958e",
      "listener": {
       "@type": "type.googleapis.com/envoy.config.listener.v3.Listener",
       "name": "inbound:10.244.0.6:5000",
       "address": {
        "socket_address": {
         "address": "10.244.0.6",
         "port_value": 5000
        }
       }
      }
     }
```

Using the Kuma counter demo app as an example, when the client needs to talk to the node app, it does not do so over 15006, but rather the actual application port, 5000. This is the “transparent” part of the proxying as it is not expected that apps will need to be redesigned or changed in any way to utilize mesh.


So, when the request comes into the system, the IPTables rule grabs the traffic and sends it to envoy port 15006. Once here, we check where the request was originally intended to go, in this case 5000 and forward it.


A further review of the envoy config will show our Node app listener where the IP address, 10.244.0.6, is that of the demo-app pod. Now that envoy is in control of the traffic we can now
(optionally) apply filters/Mesh policies.


```json
     "name": "inbound:10.244.0.6:5000",
     "active_state": {
      "version_info": "9dac7d53-3560-4ad4-ba42-c7e563db958e",
      "listener": {
       "@type": "type.googleapis.com/envoy.config.listener.v3.Listener",
       "name": "inbound:10.244.0.6:5000",
       "address": {
        "socket_address": {
         "address": "10.244.0.6",
         "port_value": 5000
        }
       },
          "filter_chains": [
            {
              "filters": [
                {
                  "name": "envoy.filters.network.http_connection_manager",
                  "typed_config": {
                    "@type": "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager",
                    "stat_prefix": "localhost_5000",
                    "route_config": {
                    "http_filters": [
                      {
                        "name": "envoy.filters.http.fault",
                        "typed_config": {
                          "@type": "type.googleapis.com/envoy.extensions.filters.http.fault.v3.HTTPFault",
                          "delay": {
                            "fixed_delay": "5s",
                            "percentage": {
                              "numerator": 50,
                              "denominator": "TEN_THOUSAND"
...
```

### Outbound TCP Traffic


The outbound port, 15001, is the default for capturing outbound traffic from the system. That is, traffic leaving the mesh. This rule allow us to capture and redirect all TCP traffic to 15001. 


```
--append KUMA_MESH_OUTBOUND_REDIRECT --protocol tcp --jump REDIRECT --to-ports 15001
```

An envoy listener is also created for this port which we can see in the admin interface (:9901/config_dump). In the below example you can see the listener created on all interfaces (line 8) and port 15001 (line 9). This will allow us to capture and outbound traffic policies.

```json
     "name": "outbound:passthrough:ipv6",
     "active_state": {
      "listener": {
       "@type": "type.googleapis.com/envoy.config.listener.v3.Listener",
       "name": "outbound:passthrough:ipv6",
       "address": {
        "socket_address": {
         "address": "::",
         "port_value": 15001
        }
       },
      ...
       "use_original_dst": true,
       "traffic_direction": "OUTBOUND"
```


## Kubernetes

On **Kubernetes** `kuma-dp` leverages transparent proxying automatically via `iptables` installed with `kuma-init` container or CNI.
All incoming and outgoing traffic is automatically intercepted by `kuma-dp` without having to change the application code.

{{site.mesh_product_name}} integrates with a service naming provided by Kubernetes DNS as well as providing its own [{{site.mesh_product_name}} DNS](/docs/{{ page.release }}/networking/dns) for multi-zone service naming.

## Universal

On **Universal** `kuma-dp` leverages the [data plane proxy specification](/docs/{{ page.release }}/production/dp-config/dpp-on-universal#dataplane-configuration) associated to it for receiving incoming requests on a pre-defined port.

In order to enable transparent-proxy the Zone Control Plane must exist on a seperate server.  Running the Zone Control Plane with Postgres does not function with transparent-proxy on the same machine.

There are several advantages for using transparent proxying in universal mode:

 * Simpler Dataplane resource, as the `outbound` section becomes obsolete and can be skipped.
 * Universal service naming with `.mesh` [DNS domain](/docs/{{ page.release }}/networking/dns) instead of explicit outbound like `https://localhost:10001`.
 * Support for hostnames of your choice using [VirtualOutbounds](/docs/{{ page.release }}/policies/virtual-outbound) that lets you preserve existing service naming.
 * Better service manageability (security, tracing).


### firewalld support

If you run `firewalld` to manage firewalls and wrap iptables, add the `--store-firewalld` flag to `kumactl install transparent-proxy`. This persists the relevant rules across host restarts. The changes are stored in `/etc/firewalld/direct.xml`. There is no uninstall command for this feature.

### Upgrades

Before upgrading to the next version of {{site.mesh_product_name}}, it's best to clean existing `iptables` rules and only then replace the `kumactl` binary.

You can clean the rules either by restarting the host or by running following commands

{% warning %}
Executing these commands will remove all `iptables` rules, including those created by {{site.mesh_product_name}} and any other applications or services.
{% endwarning %}

```sh
iptables --table nat --flush
iptables --table raw --flush
ip6tables --table nat --flush
ip6tables --table raw --flush
iptables --table nat --delete-chain
iptables --table raw --delete-chain
ip6tables --table nat --delete-chain
ip6tables --table raw --delete-chain
```

In the future release, `kumactl` [will ship](https://github.com/kumahq/kuma/issues/8071) with `uninstall` command.

## Configuration

### Intercepted traffic

{% tabs %}
{% tab Kubernetes %}

By default, all the traffic is intercepted by Envoy. You can exclude which ports are intercepted by Envoy with the following annotations placed on the Pod

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

You can also control this value on whole {{site.mesh_product_name}} deployment with the following {{site.mesh_product_name}} CP [configuration](/docs/{{ page.release }}/documentation/configuration)

```sh
KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_INBOUND_PORTS=1234
KUMA_RUNTIME_KUBERNETES_SIDECAR_TRAFFIC_EXCLUDE_OUTBOUND_PORTS=5678,8900
```

{% endtab %}

{% tab Universal %}
By default, all ports are intercepted by the transparent proxy. This may prevent remote access to the host via SSH (port `22`) or other management tools when `kuma-dp` is not running.

If you need to access the host directly, even when `kuma-dp` is not running, use the `--exclude-inbound-ports` flag with `kumactl install transparent-proxy` to specify a comma-separated list of ports to exclude from redirection.

Run `kumactl install transparent-proxy --help` for all available options.
{% endtab %}
{% endtabs %}

### Reachable Services

By default, every data plane proxy in the mesh follows every other data plane proxy.
This may lead to performance problems in larger deployments of the mesh.
It is highly recommended to define a list of services that your service connects to.

{% tabs %}
{% tab Kubernetes %}
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
        kuma.io/transparent-proxying-reachable-services: "redis_kuma-demo_svc_6379,elastic_kuma-demo_svc_9200"
    spec:
      containers:
        ...
```
{% endtab %}
{% tab Universal %}
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
      - redis_kuma-demo_svc_6379
      - elastic_kuma-demo_svc_9200 
```
{% endtab %}
{% endtabs %}

{% if_version gte:2.9.x %}

### Reachable Backends

{% warning %}
This works only when [MeshService](/docs/{{ page.release }}/networking/meshservice) is enabled.
{% endwarning %}

Reachable Backends provides similar functionality to [reachable services](/docs/{{ page.release }}/production/dp-config/transparent-proxying#reachable-services), but it applies to [MeshService](/docs/{{ page.release }}/networking/meshservice), [MeshExternalService](/docs/{{ page.release }}/networking/meshexternalservice), and [MeshMultiZoneService](/docs/{{ page.release }}/networking/meshmultizoneservice).

By default, every data plane proxy in the mesh tracks every other data plane proxy. Configuring reachableBackends can improve performance and reduce resource utilization.

Unlike reachable services, the model for providing data in Reachable Backends is more structured.

#### Model

- **refs**: A list of all resources your application wants to track and communicate with.
  - **kind**: The type of resource. Possible values include:
    - [**MeshService**](/docs/{{ page.release }}/networking/meshservice)
    - [**MeshExternalService**](/docs/{{ page.release }}/networking/meshexternalservice)
    - **MeshMultiZoneService**
  - **name**: The name of the resource.
  - **namespace**: (Kubernetes only) The namespace where the resource is located. When this is defined, the name is required. Only on kubernetes.
  - **labels**: A list of labels to match on the resources (either `labels` or `name` can be defined).
  - **port**: (Optional) The port of the service you want to communicate with. Works with `MeshService` and `MeshMultiZoneService`

{% tabs %}
{% tab Kubernetes %}

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
            namespace: kuma-demo
            port: 8080
          - kind: MeshMulitZoneService
            labels:
              kuma.io/display-name: test-server
          - kind: MeshExternalService
            name: mes-http
            namespace: kuma-system
```
{% endtab %}
{% tab Universal %}
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
{% endtab %}
{% endtabs %}

#### Examples

##### `demo-app` communicates only with `redis` on port 6379

{% tabs %}
{% tab Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: kuma-demo
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
            namespace: kuma-demo
            port: 6379
    spec:
      containers:
        ...
```
{% endtab %}
{% tab Universal %}
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
{% endtab %}
{% endtabs %}

##### `demo-app` doesn't need to communicate with any service

{% tabs %}
{% tab Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: kuma-demo
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
{% endtab %}
{% tab Universal %}
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
{% endtab %}
{% endtabs %}

##### `demo-app` wants to communicate with all MeshServices in `kuma-demo` namespace

{% tabs %}
{% tab Kubernetes %}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: kuma-demo
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
              k8s.kuma.io/namespace: kuma-demo
    spec:
      containers:
        ...
```
{% endtab %}
{% endtabs %}

{% endif_version %}
### Transparent Proxy with eBPF (experimental)

Starting from {{site.mesh_product_name}} 2.0 you can set up transparent proxy to use eBPF instead of iptables.

{% warning %}
To use Transparent Proxy with eBPF your environment has to use `Kernel >= 5.7`
and have `cgroup2` available
{% endwarning %}

{% tabs %}
{% tab Kubernetes %}

```sh
kumactl install control-plane \
  --set "{{site.set_flag_values_prefix}}experimental.ebpf.enabled=true" | kubectl apply -f-
```

{% endtab %}

{% tab Universal %}

```sh
kumactl install transparent-proxy \
  --experimental-transparent-proxy-engine \
  --ebpf-enabled \
  --ebpf-instance-ip <IP_ADDRESS> \
  --ebpf-programs-source-path <PATH>
```

{% tip %}
If your environment contains more than one non-loopback network interface, and
you want to specify explicitly which one should be used for transparent proxying
you should provide it using `--ebpf-tc-attach-iface <IFACE_NAME>` flag, during
transparent proxy installation.
{% endtip %}

{% endtab %}
{% endtabs %}