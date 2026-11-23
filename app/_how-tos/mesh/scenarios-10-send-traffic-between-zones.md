---
title: Send traffic between zones
content_type: how_to
permalink: /mesh/send-traffic-between-zones/
description: Deploy a Kong Air service in zone2, allow a zone1 workload to call it, and confirm that the request goes through the mesh-scoped zone ingress of zone2.
breadcrumbs:
  - /mesh/
  - /mesh/scenarios/
products:
  - mesh
works_on:
  - konnect
tags:
  - multi-zone
min_version:
  mesh: '3.0'
series:
  id: mesh-kong-air-scenario
  position: 10
tldr:
  q: How do I send traffic from one zone to a service in another zone?
  a: |
    1. Deploy the service in the second zone. The global control plane syncs its `MeshService` to the other zones.
    2. In the destination zone, allow the caller's SPIFFE ID with a `MeshTrafficPermission`.
    3. Call the service with its cross-zone hostname, `NAME.NAMESPACE.svc.ZONE.mesh.local`. The caller's sidecar sends the request to the zone ingress of the destination zone.
related_resources:
  - text: Multi-zone architecture
    url: /mesh/multi-zone-architecture/
  - text: Mesh-scoped zone proxies
    url: /mesh/mesh-scoped-zone-proxies/
  - text: Match caller identities
    url: /mesh/policies/meshtrafficpermission/#match-caller-identities
  - text: Deploy mesh-scoped zone proxies
    url: /mesh/zone-proxies/
  - text: MeshService
    url: /mesh/meshservice/
---

Kong Air runs its baggage service, `baggage-api`, in its second region, `zone2`.
`passenger-portal` in `zone1` shows the baggage status of each booking, so it calls `baggage-api` across zones.

The zone ingress of `zone2` forwards the encrypted connection without decrypting it, so the `baggage-api` sidecar sees the SPIFFE ID of `passenger-portal` itself, not the zone ingress.

To learn more about what this guide does, read the following reference pages:

* [Multi-zone architecture](/mesh/multi-zone-architecture/): how a request reaches a service in another zone
* [Mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/): what the zone ingress does with the connection
* [Match caller identities](/mesh/policies/meshtrafficpermission/#match-caller-identities): how a traffic permission allows a caller from another zone

## Check the zone ingress addresses

Each zone control plane publishes the address of its zone ingress in a `MeshZoneAddress`, and the global control plane syncs it to the other zones.
List the addresses that `zone1` knows:

```sh
kubectl get meshzoneaddresses -n {{site.mesh_namespace}} \
  -o custom-columns='ZONE:.metadata.labels.kuma\.io/zone,ORIGIN:.metadata.labels.kuma\.io/origin,ADDRESS:.spec.address,PORT:.spec.port'
```

The output lists the ingress of `zone1`, and the ingress of `zone2` that the global control plane synced:

```text
ZONE    ORIGIN   ADDRESS        PORT
zone1   zone     192.168.58.2   31975
zone2   global   192.168.58.3   31823
```
{:.no-copy-code}

Each address is the node IP and the `NodePort` of the zone ingress `Service`, because the Kong Air Helm values set the ingress `Service` type to `NodePort`.
If the `zone2` entry is missing, `zone1` has no address to send cross-zone traffic to.

## Deploy baggage-api in zone2

1. Deploy `baggage-api` in the `kong-air-production` namespace of `zone2`, with sidecar injection enabled:

   ```sh
   kubectl --context "$ZONE2_CONTEXT" apply -f - <<'EOF'
   apiVersion: v1
   kind: Namespace
   metadata:
     name: kong-air-production
     labels:
       kuma.io/sidecar-injection: enabled
       kuma.io/mesh: kong-air-mesh
   ---
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: baggage-api
     namespace: kong-air-production
   ---
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: nginx-passthrough
     namespace: kong-air-production
   data:
     default.conf: |
       server {
           listen 8080;
           location / {
               add_header Content-Type text/plain;
               return 200 "$hostname\n";
           }
           location /health {
               add_header Content-Type text/plain;
               return 200 "ok\n";
           }
       }
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: baggage-api
     namespace: kong-air-production
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: baggage-api
         version: v1
     template:
       metadata:
         labels:
           app: baggage-api
           version: v1
       spec:
         serviceAccountName: baggage-api
         containers:
           - name: baggage-api
             image: nginx:alpine
             ports:
               - containerPort: 8080
             volumeMounts:
               - name: nginx-config
                 mountPath: /etc/nginx/conf.d
             readinessProbe:
               httpGet:
                 path: /health
                 port: 8080
               initialDelaySeconds: 5
               periodSeconds: 5
         volumes:
           - name: nginx-config
             configMap:
               name: nginx-passthrough
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: baggage-api
     namespace: kong-air-production
   spec:
     selector:
       app: baggage-api
     ports:
       - port: 8080
         targetPort: 8080
         name: http
         appProtocol: http
   EOF
   ```
   {:.collapsible}

1. Wait for `baggage-api` to be available:

   ```sh
   kubectl --context "$ZONE2_CONTEXT" wait -n kong-air-production \
     --for=condition=available deployment/baggage-api --timeout=180s
   ```

1. Check that `zone1` received the `baggage-api` `MeshService` from `zone2`:

   ```sh
   kubectl get meshservices -n {{site.mesh_namespace}} -l kuma.io/zone=zone2
   ```

   The `zone2` control plane generated the `MeshService`, and the global control plane synced it to `zone1`, with a hash suffix in its name:

   ```text
   NAME                           HOSTNAME
   baggage-api-5bc2845v7f9x4x88   baggage-api.kong-air-production.svc.zone2.mesh.local
   ```
   {:.no-copy-code}

   Callers in `zone1` reach `baggage-api` with the `HOSTNAME` value.

## Allow passenger-portal to call baggage-api

Allow the `zone1` SPIFFE ID of `passenger-portal`:

```sh
kubectl --context "$ZONE2_CONTEXT" apply -f - <<'EOF'
apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-passenger-portal-to-baggage
  namespace: {{site.mesh_namespace}}
  labels:
    kuma.io/mesh: kong-air-mesh
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: baggage-api
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://kong-air-mesh.zone1.mesh.local/ns/kong-air-production/sa/passenger-portal
EOF
```

The SPIFFE ID keeps the `zone1` trust domain, because the zone ingress doesn't terminate the connection.

## Validate

1. Send a request from `passenger-portal` in `zone1` to `baggage-api` in `zone2`:

   ```sh
   kubectl exec -n kong-air-production deploy/passenger-portal -- \
     wget -q -T 5 -O- http://baggage-api.kong-air-production.svc.zone2.mesh.local:8080/
   ```

   The response is the name of the `baggage-api` Pod that served the request:

   ```text
   baggage-api-66f8776c78-tz4qz
   ```
   {:.no-copy-code}

   A `403 Forbidden` response means that the request reached `zone2`, but no `MeshTrafficPermission` allows the caller.

1. Confirm that the request went through the zone ingress of `zone2`, by reading the ingress statistics through the `zone2` control plane API.
   Forward the API port in the background:

   ```sh
   kubectl --context "$ZONE2_CONTEXT" -n {{site.mesh_namespace}} port-forward svc/kong-mesh-control-plane 5681:5681 > /dev/null 2>&1 &
   export PORT_FORWARD_PID=$!
   ```

1. Get the name of the `zone2` ingress Pod, and the admin token of the `zone2` control plane.
   The statistics endpoint requires an authenticated user:

   ```sh
   export INGRESS_POD=$(kubectl --context "$ZONE2_CONTEXT" -n {{site.mesh_namespace}} get pod \
     -l app=kong-mesh-kong-air-mesh-ingress -o jsonpath='{.items[0].metadata.name}')
   export ZONE2_ADMIN_TOKEN=$(kubectl --context "$ZONE2_CONTEXT" -n {{site.mesh_namespace}} get secret admin-user-token \
     -o jsonpath='{.data.value}' | base64 -d)
   ```

1. Read the connection count of the ingress for `baggage-api`:

   ```sh
   curl -sS --fail -H "Authorization: Bearer $ZONE2_ADMIN_TOKEN" \
     "http://localhost:5681/meshes/kong-air-mesh/dataplanes/${INGRESS_POD}.{{site.mesh_namespace}}/stats" | \
     grep 'baggage-api_http.upstream_cx_total'
   ```

   The count is greater than zero:

   ```text
   cluster.kri_msvc_kong-air-mesh_zone2_kong-air-production_baggage-api_http.upstream_cx_total: 1
   ```
   {:.no-copy-code}

   Send the cross-zone request again, and the count increases.

1. Stop the port-forward:

   ```sh
   kill $PORT_FORWARD_PID
   ```
