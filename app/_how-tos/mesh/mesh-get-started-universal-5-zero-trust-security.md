---
title: Introduce zero-trust security
description: "Issue workload identities with MeshIdentity, watch traffic default to deny, and allow only what you mean to with MeshTrafficPermission."
content_type: how_to
permalink: /mesh/get-started/universal/zero-trust-security/
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
  - security
series:
  id: mesh-get-started-universal-3
  position: 5
tldr:
  q: How do I turn on mTLS and restrict traffic in {{site.mesh_product_name}} 3.x?
  a: Create a `MeshIdentity` so workloads get certificates, which makes traffic default to deny, then allow specific callers with a `MeshTrafficPermission` matching on their SPIFFE ID.
related_resources:
  - text: MeshIdentity
    url: /mesh/policies/meshidentity/
  - text: MeshTrafficPermission
    url: /mesh/policies/meshtrafficpermission/
  - text: MeshTLS
    url: /mesh/policies/meshtls/
  - text: Application ingress
    url: /mesh/application-ingress/
cleanup:
  inline:
    - title: Remove the demo containers and network
      content: |
        Remove the demo containers:

        ```sh
        docker rm --force kong-mesh-demo-app kong-mesh-demo-kv kong-mesh-demo-control-plane
        ```

        Remove the Docker network:

        ```sh
        docker network rm kong-mesh-demo
        ```

        Remove the working directory:

        ```sh
        rm -rf "$KONG_MESH_DEMO_TMP"
        ```
min_version:
  mesh: '3.0'
---

## Issue identities

A workload gets a certificate from a [MeshIdentity](/mesh/policies/meshidentity/). Without one,
proxies have no identity, serve plaintext, and neither `MeshTLS` nor `MeshTrafficPermission`
applies to them.

1. Create a `MeshIdentity` for every proxy in the mesh:

   ```sh
   cat <<'EOF' | kongctl apply mesh -f - \
     --control-plane-url "$KONG_MESH_CP" \
     --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
   type: MeshIdentity
   mesh: default
   name: demo-identity
   spec:
     selector:
       dataplane: {}
     spiffeID:
       trustDomain: default.mesh.local
     provider:
       type: Bundled
       bundled:
         autogenerate:
           enabled: true
         insecureAllowSelfSigned: true
         meshTrustCreation: Enabled
   EOF
   ```

   In this example:
   * `selector.dataplane: {}` matches every proxy in the mesh. 
   * `insecureAllowSelfSigned` accepts a CA the control plane generates itself, for testing purposes. In a real mesh, provide a CA under `bundled.ca`.
   * `trustDomain` explicitly keeps the SPIFFE IDs predictable. Left out, it's generated based on the following template: `{% raw %}{{ .Mesh }}.{{ .Zone }}.mesh.local{% endraw %}`.

1. Check that the identity initialized:

   ```sh
   kongctl get mesh meshidentities demo-identity -o yaml \
     --control-plane-url "$KONG_MESH_CP" \
     --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
   ```

   `status.conditions` should report `Provider`, `MeshTrustCreated` and `Ready` as true, and
   `status.trustDomain` shows the domain issuance is pinned to.

1. Check the `MeshTrust` the control plane created to publish the CA bundle:

   ```sh
   kongctl get mesh meshtrusts \
     --control-plane-url "$KONG_MESH_CP" \
     --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
   ```

## Confirm that traffic is denied

1. Send a request from inside the demo application's container, so the application calls the
   key/value store through its sidecar:

   ```sh
   docker exec kong-mesh-demo-app curl -s -XPOST http://127.0.0.1:5050/api/counter
   ```

   The request fails. Proxies now have identities, so `MeshTrafficPermission` applies, and no
   permission exists yet, so the `kv` proxy rejects the call from `demo-app`.

1. Send the same request from your host, outside the mesh:

   ```sh
   curl -XPOST http://127.0.0.1:25050/api/counter
   ```

   This request also fails. Inbounds are `Strict` unless a [MeshTLS](/mesh/policies/meshtls/)
   policy says otherwise, so the `demo-app` proxy rejects plaintext from outside the mesh.

## Allow the demo app to reach the key/value store

Create a `MeshTrafficPermission` that allows traffic from `demo-app` to `kv`:

```sh
cat <<'EOF' | kongctl apply mesh -f - \
  --control-plane-url "$KONG_MESH_CP" \
  --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
type: MeshTrafficPermission
mesh: default
name: allow-demo-app-to-kv
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: kv
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://default.mesh.local/workload/demo-app
EOF
```

## Inspect the applied policy

1. Check that the `MeshTrafficPermission` policy applies to the `kv` proxy:

   ```sh
   kongctl inspect mesh dataplane kv \
     --control-plane-url "$KONG_MESH_CP" \
     --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
   ```

1. Check which proxies the policy matches:

   ```sh
   kongctl inspect mesh meshtrafficpermission allow-demo-app-to-kv \
     --control-plane-url "$KONG_MESH_CP" \
     --control-plane-token "$KONG_MESH_ADMIN_TOKEN"
   ```

To let traffic from outside the mesh reach the demo application, see
[Application ingress](/mesh/application-ingress/).

## Validate

1. Send the request from inside the demo application's container again:

   ```sh
   docker exec kong-mesh-demo-app curl -s -XPOST http://127.0.0.1:5050/api/counter
   ```

   The response returns the incremented counter and the `local-demo-zone` zone name. The
   application reached `kv` over mTLS, and the `kv` proxy admitted it because `demo-app`'s SPIFFE
   ID is allowed.

   {:.info}
   > It can take a few seconds for the `MeshTrafficPermission` to be applied. If the request still fails, wait and try again.

1. Send the same request from your host again:

   ```sh
   curl -XPOST http://127.0.0.1:25050/api/counter
   ```

   It still fails: `curl` presents no mesh identity, and the inbound is `Strict`. Traffic between
   the two workloads is encrypted and authorized, and traffic from outside the mesh isn't admitted.
