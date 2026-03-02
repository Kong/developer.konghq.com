---
title: Ingress mTLS Bridge
content_type: reference
layout: how-to
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
description: A complete guide to setting up Kong Gateway as an ingress for a {{site.mesh_product_name}} mesh, ensuring secure mTLS connectivity and solving 502/504 errors.
products:
  - mesh
tldr:
  q: How do I bridge Kong Gateway into my service mesh?
  a: |
    Connect your ingress to the mesh by:
    1. **Annotating the Gateway** pod with `kuma.io/gateway: enabled`.
    2. **Creating an ExternalName** service to bridge cross-namespace traffic.
    3. **Enabling mTLS** between the Gateway and internal services for a complete zero-trust path.
next_steps:
  - text: "Chaos Engineering: Fault Injection"
    url: "/mesh/scenarios/chaos-engineering/"
---
For **Kong Air**, the journey from the public internet to their private mesh must be seamless and secure. Kong Air uses Kong Gateway as their primary ingress, and ensuring mTLS is maintained from the gateway to the internal `check-in-api` is a critical requirement.

## 1. Gateway Deployment

When deploying Kong Gateway as an ingress, you must mark the Pods so {{site.mesh_product_name}} knows they are acting as a gateway.

### The `kuma.io/gateway: enabled` Annotation

Add the following annotation to your Kong Gateway Pod template:

```yaml
metadata:
  annotations:
    kuma.io/gateway: enabled
```

**What this does:**
- Tells {{site.mesh_product_name}} this is a **Delegated Gateway**.
- **Disables standard inbound listeners**: Prevents port conflicts between Kong and {{site.mesh_product_name}} sidecars.
- **Enables outbound mTLS**: Allows Kong to use the sidecar for secure communication with mesh backends.

## 2. The mTLS Connectivity Problem

By default, the Kong Operator and therefore the Kong Gateway load balances traffic directly to **Pod IPs**. 

Because these requests bypass {{site.mesh_product_name}}'s Virtual IPs (VIPs), the sidecar on the Gateway treats them as **passthrough** traffic and sends them as **plaintext**.

- **In STRICT mTLS mode**: The backend sidecar rejects these plaintext connections, causing **502 Bad Gateway** or `Connection reset by peer` errors.

## 3. The Solution: ExternalName Bridge

To fix this, you must force Kong to use internal service discovery (and thus its VIPs). The most effective way is to use a Kubernetes `Service` of type `ExternalName`.

### Step A: Create the Bridge Service

Create a service that points to the {{site.mesh_product_name}}-native FQDN of your backend.

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

### Step B: Configure the HTTPRoute

Update your `HTTPRoute` to point to the bridge service.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: check-in-ingress
  namespace: kong-air-production
spec:
  parentRefs: [{ name: kong-air-gateway }]
  rules:
    - backendRefs:
        - name: check-in-mesh-bridge # The ExternalName bridge
          port: 8080
```

## Traffic Flow Analysis

1. **Kong** resolves `check-in-mesh-bridge` via DNS.
2. **{{site.mesh_product_name}} DNS** returns a **Virtual IP (VIP)**.
3. **Kong** sends the request to the VIP.
4. **Gateway Sidecar** intercepts the VIP, identifies the mesh service, and **upgrades the connection to mTLS**.
5. **Backend Sidecar** receives the mTLS connection, satisfying **STRICT** requirements.

{% warning %}
This pattern ensures your ingress traffic is fully encrypted and authenticated within the mesh, even when using third-party ingress controllers like Kong.
{% endwarning %}
