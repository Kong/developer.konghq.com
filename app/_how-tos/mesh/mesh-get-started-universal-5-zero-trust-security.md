---
title: Introduce zero-trust security with {{site.mesh_product_name}}
description: "Enable mTLS and configure the built-in gateway to secure {{site.mesh_product_name}} services and allow external traffic into the mesh."
content_type: how_to
permalink: /mesh/get-started/universal/zero-trust-security/
breadcrumbs:
  - /mesh/
products:
  - mesh
works_on:
  - on-prem
tags:
  - get-started
  - universal-mode
  - docker
min_version:
  mesh: '2.10'
series:
  id: mesh-get-started-universal
  position: 5
tldr:
  q: How do I secure services in {{site.mesh_product_name}} with zero-trust security?
  a: Enable mTLS with a built-in CA to encrypt all traffic, apply MeshTrafficPermission policies to control access, and configure a built-in gateway to route external traffic into the mesh.
cleanup:
  inline:
    - title: Clean up Docker resources
      content: |
        Remove the Docker containers, network, temporary directory, and the control plane configuration from [kumactl](/mesh/cli/):

        ```sh
        kumactl config control-planes remove --name kong-mesh-demo

        docker rm --force \
           kong-mesh-demo-control-plane \
           kong-mesh-demo-kv \
           kong-mesh-demo-app \
           kong-mesh-demo-edge-gateway

        docker network rm kong-mesh-demo

        rm -rf /tmp/kong-mesh-demo
        ```
next_steps:
  - text: Explore {{site.mesh_product_name}} enterprise features
    url: /mesh/enterprise/
  - text: Visualize your mesh with the {{site.mesh_product_name}} GUI
    url: /mesh/interact-with-control-plane/
  - text: Read the full {{site.mesh_product_name}} documentation
    url: /mesh/
  - text: Deploy in single-zone mode
    url: /mesh/single-zone/
  - text: Deploy in multi-zone mode
    url: /mesh/mesh-multizone-service-deployment/
---

By default, the network is insecure and unencrypted. With {{site.mesh_product_name}}, you can enable the [Mutual TLS (mTLS)](/mesh/policies/mutual-tls/) policy to secure the network. It sets up a Certificate Authority (CA) that automatically provides TLS certificates to your services, specifically to the data plane proxies running next to each service.

## Enable Mutual TLS

Enable Mutual TLS using a `builtin` CA backend:

```sh
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive
mtls:
  enabledBackend: ca-1
  backends:
  - name: ca-1
    type: builtin' | kumactl apply -f -
```

After enabling mTLS, all traffic is encrypted and secure. However, you can no longer access the `demo-app` directly, meaning <http://127.0.0.1:25050> will no longer work. This happens for two reasons:

* {{site.mesh_product_name}} doesn't create traffic permissions by default when mTLS is enabled. No traffic will flow until you define a [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) policy.
* Browsers and HTTP clients outside the mesh don't have a valid certificate signed by the `ca-1` CA, so their connections are rejected.

## Allow traffic between `demo-app` and `kv`

Apply a [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) policy to allow traffic between the `kv` and `demo-app` services:

```sh
echo 'type: MeshTrafficPermission 
name: allow-kv-from-demo-app
mesh: default 
spec: 
  targetRef:
    kind: Dataplane
    labels:
      app: kv
  from: 
  - targetRef: 
      kind: MeshSubset 
      tags:
        kuma.io/service: demo-app
    default: 
      action: Allow' | kumactl apply -f -
```

To allow external traffic into the mesh, we'll use the [built-in gateway](/mesh/built-in-gateway/) that {{site.mesh_product_name}} provides.

## Create a `Dataplane` resource

The built-in gateway needs its own `Dataplane` resource, separate from the service data plane proxies. Unlike the service `Dataplane` template used in previous steps, the gateway uses a static configuration since there's only one instance:

```sh
echo 'type: Dataplane
mesh: default
name: edge-gateway-instance-1
networking:
  gateway:
    type: BUILTIN
    tags:
      kuma.io/service: edge-gateway
  address: 172.57.78.4' > "$KONG_MESH_DEMO_TMP/dataplane-edge-gateway.yaml"
```

## Generate a data plane token

The gateway proxy requires a data plane token to securely register with the control plane. Generate the token using the following command:

```sh
kumactl generate dataplane-token \
  --tag kuma.io/service=edge-gateway \
  --valid-for 720h \
  > "$KONG_MESH_DEMO_TMP/token-edge-gateway"
```

## Start the gateway container

With the configuration and token in place, we can start the gateway proxy as a container:

```sh
docker run \
  --detach \
  --name kong-mesh-demo-edge-gateway \
  --hostname gateway \
  --network kong-mesh-demo \
  --ip 172.57.78.4 \
  --publish 28080:8080 \
  --volume "$KONG_MESH_DEMO_TMP:/demo" \
  kong/kuma-dp:{{site.data.mesh_latest.version}} run \
    --cp-address https://control-plane:5678 \
    --dataplane-token-file /demo/token-edge-gateway \
    --dataplane-file /demo/dataplane-edge-gateway.yaml \
    --dns-enabled=false
```

This command starts the gateway proxy and registers it with the control plane. However, the gateway is not yet ready to route traffic.

## Configure the gateway with `MeshGateway`

To enable the gateway to accept external traffic, configure it with a [`MeshGateway`](/mesh/meshgateway/). This setup defines listeners that specify the port, protocol, and tags for incoming traffic, allowing policies like [`MeshHTTPRoute`](/mesh/policies/meshhttproute/) or [`MeshTCPRoute`](/mesh/policies/meshtcproute/) to route traffic to services:

```sh
echo 'type: MeshGateway
mesh: default
name: edge-gateway
selectors:
- match:
    kuma.io/service: edge-gateway
conf:
  listeners:
  - port: 8080
    protocol: HTTP
    tags:
      port: http-8080' | kumactl apply -f -
```

This sets up the gateway to listen on port `8080` using the HTTP protocol and adds the tag `port: http-8080` to identify this listener in routing policies.

You can test the gateway by visiting <http://127.0.0.1:28080>. You should see a message saying no routes match this `MeshGateway`. This means the gateway is running, but no routes are set up yet to handle traffic.

## Create a route to connect the gateway to `demo-app`

To route traffic from the gateway to the service, create a [`MeshHTTPRoute`](/mesh/policies/meshhttproute/) policy:

```sh
echo 'type: MeshHTTPRoute
name: edge-gateway-demo-app-route
mesh: default
spec:
  targetRef:
    kind: MeshGateway
    name: edge-gateway
    tags:
      port: http-8080
  to:
  - targetRef:
      kind: Mesh
    rules:
    - matches:
      - path:
          type: PathPrefix
          value: "/"
      default:
        backendRefs:
        - kind: MeshService
          name: demo-app' | kumactl apply -f -
```

This route connects the gateway and its listener to the `demo-app` service. It forwards any requests with the path prefix `/` to `demo-app`.

After setting up this route, the gateway will try to send traffic to `demo-app`. However, if you test it by visiting <http://127.0.0.1:28080>, you'll see:

```
RBAC: access denied
```
{:.no-copy-code}

This happens because there is no [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) policy allowing traffic from the gateway to `demo-app`.

## Allow traffic from the gateway to `demo-app`

To fix the `RBAC: access denied` error, create a [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) policy to allow the gateway to send traffic to `demo-app`:

```sh
echo 'type: MeshTrafficPermission
name: allow-demo-app-from-edge-gateway
mesh: default
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: demo-app
  from:
  - targetRef:
      kind: MeshSubset
      tags:
        kuma.io/service: edge-gateway
    default:
      action: Allow' | kumactl apply -f -
```

This policy allows traffic from the gateway to `demo-app`. After applying it, you can access <http://127.0.0.1:28080>, and the traffic will reach the `demo-app` service successfully.
