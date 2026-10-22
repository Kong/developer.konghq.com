---
title: Add the demo application
description: "Run a second Universal workload that reaches the key/value store by name, and see the policies that now apply to it."
content_type: how_to
permalink: /mesh/get-started/universal/demo-app/
breadcrumbs:
  - /mesh/
products:
  - mesh
works_on:
  - on-prem
tools:
  - kongctl
tags:
  - get-started
  - universal-mode
  - docker
series:
  id: mesh-get-started-universal-3
  position: 4
tldr:
  q: How does the demo app reach the key/value store?
  a: Run the demo app with a sidecar and transparent proxying, and list `kv` in its `Dataplane`'s `reachableBackends`. The app then calls `kv.svc.mesh.local`, the hostname the control plane generated for the `kv` `MeshService`, and the sidecar resolves the name and routes the request.
faqs:
  - q: How does the demo app find `kv` by its hostname?
    a: |
      Three pieces make that workallow the demo app to reach `kv` by a hostname:

      - The control plane generated a `MeshService` named `kv`, and allocated
        a VIP and the `kv.svc.mesh.local` hostname.
      - The `demo-app` `Dataplane` lists `kv` in `reachableBackends`, so the control plane
        configures the proxy with an outbound for it.
      - `kuma-dp` is running with transparent proxying and the embedded DNS proxy, so the
        application's DNS lookups resolve mesh hostnames and the sidecar intercepts its outbound traffic.
  - q: How does a workload reach another one without transparent proxying?
    a: |
      Without transparent proxying, the sidecar doesn't intercept outbound traffic, so each
      destination needs an explicit outbound in the caller's `Dataplane` that binds a local port:

      ```yaml
      networking:
        address: 172.18.78.3
        inbound:
          - port: 5050
            name: main
            protocol: http
        outbound:
          - port: 10001
            backendRef:
              kind: MeshService
              name: kv
              port: 5050
      ```

      The application then connects to `127.0.0.1:10001` instead of `kv.svc.mesh.local`.
      `backendRef` is required and needs `name` or `labels`.
related_resources:
  - text: Universal data plane
    url: /mesh/universal-data-plane/
  - text: "{{site.mesh_product_name}} CLI"
    url: /mesh/cli/
min_version:
  mesh: '3.0'
---

## Start and configure the container 

Follow the same steps as for the `kv` service to configure the container for the `demo-app` service.

1. Issue a data plane token:

   ```sh
   kongctl create mesh dataplane-token \
     --control-plane-url "$KONG_MESH_CP" \
     --control-plane-token "$KONG_MESH_ADMIN_TOKEN" \
     --name demo-app \
     --workload demo-app \
     --valid-for 24h > "$KONG_MESH_DEMO_TMP/token-demo-app"
   ```

1. Start the container and include the `kv` URL:
```sh
docker run \
  --detach \
  --name kong-mesh-demo-app \
  --hostname demo-app \
  --network kong-mesh-demo \
  --ip 172.18.78.3 \
  --publish 25050:5050 \
  --volume "$KONG_MESH_DEMO_TMP:/demo" \
  --env KV_URL=http://kv.svc.mesh.local:5050 \
  --env APP_VERSION=v1 \
  ghcr.io/kumahq/kuma-counter-demo:debian-slim
```

1. Install the sidecar binaries:

   ```sh
   docker exec kong-mesh-demo-app sh /demo/setup-sidecar.sh
   ```

1. Install the transparent proxy:

   ```sh
   docker exec --privileged kong-mesh-demo-app \
     kumactl install transparent-proxy \
       --config /demo/transparent-proxy.yaml
   ```

## Write the demo app's Dataplane

Create the `Dataplane` resource for `demo-app`, with `kv` as a reachable backend:

```sh
cat > "$KONG_MESH_DEMO_TMP/dataplane-demo-app.yaml" <<'EOF'
type: Dataplane
mesh: default
name: demo-app
labels:
  kuma.io/workload: demo-app
  app: demo-app
networking:
  address: 172.18.78.3
  inbound:
    - port: 5050
      name: main
      protocol: http
  transparentProxying:
    reachableBackends:
      refs:
        - kind: MeshService
          labels:
            kuma.io/display-name: kv
EOF
```

## Start the sidecar

Run `kuma-dp` to start the `demo-app` sidecar:

```sh
docker exec --detach kong-mesh-demo-app sh -c '
  runuser -u kuma-dp -- kuma-dp run \
    --cp-address https://control-plane:5678 \
    --skip-verify \
    --dataplane-file /demo/dataplane-demo-app.yaml \
    --dataplane-token-file /demo/token-demo-app \
    --transparent-proxy-config /demo/transparent-proxy.yaml \
    > /demo/logs-demo-app.log 2>&1'
```

## Validate

1. Increment the counter through the published port:

   ```sh
   curl -XPOST http://127.0.0.1:25050/api/counter
   ```

   The response looks like this:

   ```json
   {"counter":1,"zone":"local-demo-zone"}
   ```
   {:.no-copy-code}

   You can also open the app at <http://127.0.0.1:25050> and increment the counter there.

1. Check that both workloads are now in the mesh:

   ```sh
   kongctl inspect mesh dataplanes \
     --control-plane-url "$KONG_MESH_CP" \
     --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
   ```
