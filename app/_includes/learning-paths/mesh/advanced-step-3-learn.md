Kong Air's public traffic enters through {{site.base_gateway}}: passengers hit `kongair.com` which terminates at the gateway, which then forwards to mesh-internal services like `check-in-api`. Once you've enabled strict mTLS on the mesh (previous path's Step 2), this configuration breaks in a specific, frustrating way: {{site.base_gateway}} starts returning `502 Bad Gateway`, mesh sidecars start logging "connection reset by peer", and nothing about either component's individual config looks wrong.

This step explains why it breaks and how to fix it.

### The two-line cause

The diagnosis is simple, even if the resolution takes a few resources:

1. {{site.base_gateway}}, like most ingress controllers, load-balances directly to **pod IPs** by default.
2. A pod-IP request bypasses the mesh's **VIP-based DNS layer**, so the gateway's sidecar treats it as **passthrough** traffic and sends it as **plaintext** to the destination pod.
3. The destination pod's sidecar — in strict mTLS mode — rejects any non-mTLS connection.

Result: `502`. From {{site.base_gateway}}'s logs you see a connect failure; from the destination sidecar's logs you see a TLS-handshake-with-no-handshake failure; from the mesh's perspective nothing is wrong, because the destination is just doing what strict mTLS is supposed to do.

### Two fixes, one annotation and one bridge

The full solution is two resources, deployed together.

#### 1. Mark {{site.base_gateway}}'s pods as a Delegated Gateway

Add the `kuma.io/gateway: enabled` annotation to {{site.base_gateway}}'s Pod template:

```yaml
metadata:
  annotations:
    kuma.io/gateway: enabled
```

This tells the {{site.mesh_product_name}} CP that the gateway is a special kind of workload:

- **Inbound listeners are disabled** on the sidecar — {{site.base_gateway}} owns the inbound path; the sidecar would otherwise conflict on port numbers.
- **Outbound mTLS is enabled** — the sidecar handles mTLS origination for traffic leaving the gateway, exactly like it does for in-mesh services.

Without this annotation you get port conflicts; with it, {{site.base_gateway}}'s sidecar is correctly configured to encrypt outbound calls.

#### 2. Force traffic to go through mesh DNS via an `ExternalName` bridge

This is the bit that solves the pod-IP problem. Create a Kubernetes `Service` of type `ExternalName` whose `externalName` is the mesh-internal DNS name of the backend:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: check-in-mesh-bridge
  namespace: kong-air-production
spec:
  type: ExternalName
  externalName: check-in-api.kong-air-production.svc.mesh.local
```

Then update your `HTTPRoute` (or {{site.base_gateway}}'s upstream config) to point at the bridge service instead of the original backend:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: check-in-ingress
spec:
  parentRefs: [{ name: kong-air-gateway }]
  rules:
    - backendRefs:
        - name: check-in-mesh-bridge   # The bridge, not the real Service
          port: 8080
```

When {{site.base_gateway}} resolves `check-in-mesh-bridge`, Kubernetes follows the `ExternalName` to `check-in-api.kong-air-production.svc.mesh.local`. Mesh DNS resolves that to a **VIP**. {{site.base_gateway}} sends the request to the VIP. The sidecar intercepts it, identifies the mesh service, and **originates mTLS** to the destination pod.

The end-to-end path becomes:

```
Internet ──► Kong Gateway ──► bridge Service ──► mesh DNS ──► VIP ──► Gateway sidecar (mTLS) ──► Backend sidecar (accepts mTLS) ──► Backend pod
```

Every hop in the mesh portion is mTLS, satisfying the strict requirement, and the destination sidecar accepts the connection cleanly.

### Why not just turn off strict mTLS on the destination?

You could, and a lot of teams do. But every workload in the mesh you carve out as an exception is one more thing your zero-trust audit has to document. The bridge pattern lets you keep `MeshTLS: Strict` mesh-wide and still bridge in external ingresses — strictly better posture, only marginally more setup.

The alternative path — running {{site.base_gateway}} _inside_ the mesh with no sidecar bypass — is also possible (see [{{site.base_gateway}} as a mesh-native gateway](/mesh/integrations/kong-gateway/)) but requires more careful coordination on listener ports and is overkill if you just need a public ingress to talk to mesh services.

### What you don't need to do

A few things this _isn't_:

- It isn't necessary to give {{site.base_gateway}} its own `MeshIdentity`. The gateway's sidecar gets the same identity as any other workload via the default identity flow.
- It isn't necessary to add a `MeshTrafficPermission` allowing the gateway → backend flow specifically; the default policies that allow ingress to talk to applications continue to apply. (You may want to _tighten_ it as a separate exercise.)
- It isn't necessary to disable mTLS on the route's `backendRefs`. The bridge does the work.

### Further reading

- [{{site.base_gateway}} as a mesh ingress](/mesh/integrations/kong-gateway/)
- [Delegated gateways reference](/mesh/delegated-gateways/)
- [The `kuma.io/gateway` annotation](/mesh/sidecar-annotations/)
