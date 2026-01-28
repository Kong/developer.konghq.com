---
title: "{{site.mesh_product_name}} data plane on Universal"
description: Configure data plane proxies on VMs or bare metal with manual Dataplane resource definitions and lifecycle management.

content_type: reference
layout: reference
products:
  - mesh
breadcrumbs:
  - /mesh/

tags:
  - data-plane

related_resources:
  - text: Deploy {{site.mesh_product_name}} on Universal
    url: '/mesh/universal/'
  - text: 'Data plane on Kubernetes'
    url: '/mesh/data-plane-kubernetes/'
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'
  - text: Zone ingress
    url: /mesh/zone-ingress/
  - text: "Data plane proxy"
    url: /mesh/data-plane-proxy/
  - text: Configure data plane proxy membership
    url: /mesh/configure-data-plane-proxy-membership/
---

To connect your services to the control plane, you need one or more data planes. To create a data plane on Universal, you need to create a data plane definition and pass it to the `kuma-dp run` command.

{:.info}
> On Universal, data planes need to start with a token for authentication. 
> To learn how to generate tokens, see the [data plane authentication docs](/mesh/dp-auth/#data-plane-proxy-token).

When transparent proxying isn't enabled, the outbound service dependencies have to be manually specified in the [`Dataplane`](/mesh/data-plane-proxy/#dataplane-entity) entity.
This also means that without transparent proxying, you must update your codebases to consume those external services on `127.0.0.1`, on the port specified in the `outbound` section.

{:.info}
> To avoid users bypassing the proxy, have the service listen only on the internal interface (`127.0.0.1` or `::1`) instead of all interfaces (`0.0.0.0` or `::`).

For example, here's how to start a `Dataplane` for a Redis service, and then start the `kuma-dp` process:

```sh
cat dp.yaml
type: Dataplane
mesh: default
name: redis-1
networking:
  address: 23.234.0.1 # IP of the instance
  inbound:
  - port: 9000
    servicePort: 6379
    tags:
      kuma.io/service: redis

kuma-dp run \
  --cp-address=https://127.0.0.1:5678 \
  --dataplane-file=dp.yaml
  --dataplane-token-file=/tmp/kuma-dp-redis-1-token
```

In the example above, any external client who wants to consume Redis through the sidecar will have to use `23.234.0.1:9000`, which will redirect to the Redis service listening on address `127.0.0.1:6379`. If your service doesn't listen on `127.0.0.1` and you can't change the address it listens on, you can set the `serviceAddress`:

```yaml
type: Dataplane
...
networking:
  ...
  inbound:
  - port: 9000
    serviceAddress: 192.168.1.10
    servicePort: 6379
    ...
```

This configuration indicates that your service is listening on `192.168.1.10`, and incoming traffic will be redirected to that address.


Now let's assume that we have another service called "Backend" that listens on port `80`, and that makes outgoing requests to the `redis` service:

```sh
cat dp.yaml
type: Dataplane
mesh: default
name: {{ name }}
networking:
  address: {{ address }}
  inbound:
  - port: 8000
    servicePort: 80
    tags:
      kuma.io/service: backend
      kuma.io/protocol: http
  outbound:
  - port: 10000
    tags:
      kuma.io/service: redis

kuma-dp run \
  --cp-address=https://127.0.0.1:5678 \
  --dataplane-file=dp.yaml \
  --dataplane-var name=`hostname -s` \
  --dataplane-var address=192.168.0.2 \
  --dataplane-token-file=/tmp/kuma-dp-backend-1-token
```

For the `backend` service to successfully consume `redis`, you must specify an `outbound` networking section in the `Dataplane` configuration instructing the data plane to listen on a new port `10000` and to proxy any outgoing requests on port `10000` to the `redis` service.
For this to work, you must update your application to consume `redis` on `127.0.0.1:10000`.

{:.info}
> You can parametrize your `Dataplane` definition to reuse the same file for many `kuma-dp` instances or even services.

## Lifecycle

On Universal you can manage `Dataplane` resources either in direct mode or in indirect mode:
* [Direct mode](#direct): The `Dataplane` resource is created at the same time as the data plane proxy. This is the recommended method of operating `Dataplane` resources on Universal.
* [Indirect mode](#indirect): The `Dataplane` resource is created before the data plane proxy starts. This can be useful if you have some external components that manage the `Dataplane` lifecycle.

### Direct

Direct mode is the recommended way to operate with `Dataplane` resources on Universal.

#### Joining the mesh

To allow the data plane to join the mesh, pass the `Dataplane` resource directly to the `kuma-dp run` command. 
The `Dataplane` resource can be a [Mustache template](http://mustache.github.io/mustache.5.html):

```yaml
type: Dataplane
mesh: default
name: { { name } }
networking:
  address: { { address } }
  inbound:
    - port: 8000
      servicePort: 80
      tags:
        kuma.io/service: backend
        kuma.io/protocol: http
```

The command with template parameters looks like this:

```shell
kuma-dp run \
  --dataplane-file=backend-dp-tmpl.yaml \
  --dataplane-var name=my-backend-dp \
  --dataplane-var address=192.168.0.2 \
  ...
```

When xDS connection between the proxy and kuma-cp is established, the `Dataplane` resource is created automatically by kuma-cp.

To join the mesh in a graceful way, you need to make sure the application is ready to serve traffic before it can be considered a valid traffic destination.
By default, a proxy will be considered healthy regardless of its state. 
Consider using [service probes](/mesh/dataplane-health/#kubernetes-and-universal-service-probes) to mark the data plane proxy as healthy only after all health checks are passed.

#### Leaving the mesh

To allow the data plane to leave the mesh in a graceful shutdown, you need to remove the traffic destination from all the clients before shutting it down.

Upon receiving SIGTERM, the `kuma-dp` process starts listener draining in Envoy, then it waits for the draining time before stopping the process.
During the draining process, Envoy can still accept connections, however:

1. It is marked as unhealthy on the Envoy Admin `/ready` endpoint
1. It sends `connection: close` for HTTP/1.1 requests and GOAWAY frame for HTTP/2. This forces clients to close a connection and reconnect to the new instance.

If the application next to the `kuma-dp` process quits immediately after the SIGTERM signal, there's a high chance that clients will still try to send traffic to this destination.
To mitigate this, we need to support graceful shutdown in the application. For example, the application should wait X seconds to exit after receiving the first SIGTERM signal.

Consider using [service probes](/mesh/dataplane-health/#kubernetes-and-universal-service-probes) to mark data plane proxy as unhealthy when it is in draining state.

If the data plane proxy is shutdown gracefully, the control plane automatically deletes the `Dataplane` resource.

If the data plane proxy goes down ungracefully, the `Dataplane` resource isn't deleted immediately. The following sequence of the events should happen:

{% capture ungraceful-shutdown %}
1. After the time specified in `KUMA_METRICS_DATAPLANE_IDLE_TIMEOUT` (five minutes by default), the data plane proxy is marked as offline. This is because there's no active xDS connection between the proxy and kuma-cp.
1. After the time specified in `KUMA_RUNTIME_UNIVERSAL_DATAPLANE_CLEANUP_AGE` (75 hours by default), offline data plane proxies are deleted.
{% endcapture %}

{{ungraceful-shutdown}}

This guarantees that `Dataplane` resources are eventually cleaned up even in the case of ungraceful shutdown.

### Indirect

This lifecycle is called indirect because there is no strict dependency between the `Dataplane` resource creation and the
startup of the data plane proxy. 
This can be useful if you have some external components that manage the `Dataplane` lifecycle.

#### Joining the mesh

The `Dataplane` resource is created using the HTTP API or [kumactl](/mesh/cli/#kumactl). 
It's created before the data plane proxy starts. 
There is no support for templates, resource should be a valid `Dataplane` configuration.

When the data plane proxy starts, it takes `name` and `mesh` as an input arguments:

```sh
kuma-cp run \
  --name=my-backend-dp \
  --mesh=default \
  ...
```

After the connection between the proxy and kuma-cp is established, kuma-cp finds the `Dataplane` resource with `name` and `mesh` in the store.

To allow the data plane to join the mesh in a graceful way, you can use [service probes](/mesh/dataplane-health/#kubernetes-and-universal-service-probes).

#### Leaving the mesh

In indirect mode, kuma-cp will never delete the `Dataplane` resource (with both graceful and ungraceful shutdowns).

If a data plane proxy is shutdown gracefully, then the `Dataplane` resource is marked as offline. 
Offline data plane proxies are deleted automatically after the time specified in `KUMA_RUNTIME_UNIVERSAL_DATAPLANE_CLEANUP_AGE` (72 hours by default).

If data plane proxy went down ungracefully, then the following sequence of the events should happen:

{{ungraceful-shutdown}}

To allow the data plane to leave the mesh in a graceful way, you can use [service probes](/mesh/dataplane-health/#kubernetes-and-universal-service-probes).

## Envoy configuration

`Envoy` has a powerful [Admin API](https://www.envoyproxy.io/docs/envoy/latest/operations/admin) for monitoring and troubleshooting.

By default, `kuma-dp` starts the Envoy Admin API on the loopback interface. The port is configured in the `Dataplane` entity:

```yaml
type: Dataplane
mesh: default
name: my-dp
networking:
  admin:
    port: 1000
# ...
```

If the `admin` section is empty or if the port is equal to zero, then the default value for port will be taken from the [{{site.mesh_product_name}} control plane configuration](/mesh/reference/kuma-cp/).

## Dataplane resource configuration

{% json_schema Dataplane type=proto %}
