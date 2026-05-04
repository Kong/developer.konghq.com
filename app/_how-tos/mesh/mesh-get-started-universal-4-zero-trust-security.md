---
title: Introduce zero-trust security
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
  mesh: '2.9'
series:
  id: mesh-get-started-universal
  position: 4
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

        If you're using Colima, replace `/tmp/kong-mesh-demo` with `/tmp/colima/kong-mesh-demo`.
---

By default, the network is **insecure and unencrypted**. With {{site.mesh_product_name}}, you can enable the [Mutual TLS (mTLS)](/mesh/policies/mutual-tls/) policy to secure the network. This works by setting up a Certificate Authority (CA) that automatically provides TLS certificates to your services (specifically to the data plane proxies running next to each service).

To enable Mutual TLS using a `builtin` CA backend, run the following command:

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

After enabling mTLS, all traffic is **encrypted and secure**. However, you can no longer access the `demo-app` directly, meaning <http://127.0.0.1:25050> will no longer work. This happens for two reasons:

<!-- vale Vale.Terms = NO -->
1. When mTLS is enabled, {{site.mesh_product_name}} doesn't create traffic permissions by default. This means no traffic will flow until you define a [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy to allow `demo-app` to communicate with `kv`.

2. When you try to call `demo-app` using a browser or other HTTP client, you are essentially acting as an external client without a valid TLS certificate. Since all services are now required to present a certificate signed by the `ca-1` Certificate Authority, the connection is rejected. Only services within the `default` mesh, which are assigned valid certificates, can communicate with each other.
<!-- vale Vale.Terms = YES -->

To address the first issue, you need to apply an appropriate [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy:

```sh
echo 'type: MeshTrafficPermission 
name: allow-kv-from-demo-app
mesh: default 
spec: 
  targetRef:
    kind: {% if_version lte:2.9.x %}MeshSubset
    tags:
      kuma.io/service{% endif_version %}{% if_version gte:2.10.x %}Dataplane
    labels:
      app{% endif_version %}: kv
  from: 
  - targetRef: 
      kind: MeshSubset 
      tags:
        kuma.io/service: demo-app
    default: 
      action: Allow' | kumactl apply -f -
```

The second issue is a bit more challenging. You can't just get the necessary certificate and set up your web browser to act as part of the mesh. To handle traffic from outside the mesh, you need a _gateway proxy_. You can use tools like [Kong](https://github.com/Kong/kong), or you can use the [Built-in Gateway](/mesh/built-in-gateway/) that {{site.mesh_product_name}} provides.

{:.info}
> **Note:** For more information, see the [Managing incoming traffic with gateways](/mesh/ingress/) section in the documentation.

In this guide, we'll use the built-in gateway. It allows you to configure a data plane proxy to act as a gateway and manage external traffic securely.

## Set up the built-in gateway

The built-in gateway works like the data plane proxy for a regular service, but it requires its own configuration. Here's how to set it up step by step.

1. **Create a Dataplane resource**

   For regular services, we reused a single [Dataplane](/mesh/data-plane-proxy/) configuration file and provided dynamic values (like names and addresses) when starting the data plane proxy. This made it easier to scale or deploy multiple instances. However, since we're deploying only one instance of the gateway, we can simplify things by hardcoding all the values directly into the file, as shown below:

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

   If you prefer to keep the flexibility of dynamic values, you can use the same template mechanisms for the gateway's [Dataplane](/mesh/data-plane-proxy/) configuration as you did for regular services.

2. **Generate a data plane token**

   The gateway proxy requires a data plane token to securely register with the control plane. You can generate the token using the following command:

   ```sh
   kumactl generate dataplane-token \
     --tag kuma.io/service=edge-gateway \
     --valid-for 720h \
     > "$KONG_MESH_DEMO_TMP/token-edge-gateway"
   ```

3. **Start the gateway container**

   With the configuration and token in place, you can start the gateway proxy as a container:

   ```sh
   docker run \
     --detach \
     --name kong-mesh-demo-edge-gateway \
     --hostname gateway \
     --network kong-mesh-demo \
     --ip 172.57.78.4 \
     --publish 28080:8080 \
     --volume "$KONG_MESH_DEMO_TMP:/demo" \
     kong/kuma-dp:latest run \
       --cp-address https://control-plane:5678 \
       --dataplane-token-file /demo/token-edge-gateway \
       --dataplane-file /demo/dataplane-edge-gateway.yaml \
       --dns-enabled=false
   ```

   This command starts the gateway proxy and registers it with the control plane. However, the gateway is not yet ready to route traffic.

4. **Configure the gateway with [MeshGateway](/mesh/gateway-listeners/)**

   To enable the gateway to accept external traffic, configure it with a [MeshGateway](/mesh/gateway-listeners/). This setup defines listeners that specify the port, protocol, and tags for incoming traffic, allowing policies like [MeshHTTPRoute](/mesh/policies/meshhttproute/) or [MeshTCPRoute](/mesh/policies/meshtcproute/) to route traffic to services.

   Apply the configuration:

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

   <!-- vale Vale.Terms = NO -->
   This sets up the gateway to listen on port `8080` using the HTTP protocol and adds a tag (`port: http-8080`) to identify this listener in routing policies.
   <!-- vale Vale.Terms = YES -->

   You can test the gateway by visiting <http://127.0.0.1:28080>. You should see a message saying no routes match this [MeshGateway](/mesh/gateway-listeners/). This means the gateway is running, but no routes are set up yet to handle traffic.

5. **Create a route to connect the gateway to `demo-app`**

   To route traffic from the gateway to the service, create a [MeshHTTPRoute](/mesh/policies/meshhttproute/) policy:

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

   This route connects the gateway and its listener (`port: http-8080`) to the `demo-app` service. It forwards any requests with the path prefix `/` to `demo-app`.

   After setting up this route, the gateway will try to send traffic to `demo-app`. However, if you test it by visiting <http://127.0.0.1:28080>, you'll see:

   ```
   RBAC: access denied
   ```
   {:.no-line-numbers}

   This happens because there is no [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy allowing traffic from the gateway to `demo-app`. You'll need to create one in the next step.

6. **Allow traffic from the gateway to `demo-app`**

   To fix the `RBAC: access denied` error, create a [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy to allow the gateway to send traffic to `demo-app`:

   ```sh
   echo 'type: MeshTrafficPermission
   name: allow-demo-app-from-edge-gateway
   mesh: default
   spec:
     targetRef:
       kind: {% if_version lte:2.9.x %}MeshSubset
       tags:
         kuma.io/service{% endif_version %}{% if_version gte:2.10.x %}Dataplane
       labels:
         app{% endif_version %}: demo-app
     from:
     - targetRef:
         kind: MeshSubset
         tags:
           kuma.io/service: edge-gateway
       default:
         action: Allow' | kumactl apply -f -
   ```

   This policy allows traffic from the gateway to `demo-app`. After applying it, you can access <http://127.0.0.1:28080>, and the traffic will reach the `demo-app` service successfully.

## Next steps

- Explore all [features](/mesh/enterprise/) to better understand {{site.mesh_product_name}}'s capabilities.
- Try using the [{{site.mesh_product_name}} GUI](/mesh/interact-with-control-plane/) to easily visualize your mesh.
- Read the [full documentation](/mesh/) for more details.
- Check deployment examples for [single-zone](/mesh/single-zone/) or [multi-zone](/mesh/mesh-multizone-service-deployment/) setups.
