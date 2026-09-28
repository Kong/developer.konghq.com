## Create a mesh and secure the test traffic

Install a [kongctl build with Mesh 3 support](/mesh/cli/) and log in to the same Konnect organization:

```sh
kongctl login
kongctl get mesh resource-types --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
```

Create a new `konnect-demo` mesh, a demo identity provider, and permission for the `client`
ServiceAccount to call the `server` workload. Apply these resources to the **global** control
plane, not directly to the Kubernetes zone:

```sh
cat <<'EOF' | kongctl create mesh -f - --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
type: Mesh
name: konnect-demo
---
type: MeshIdentity
mesh: konnect-demo
name: demo-identity
spec:
  selector:
    dataplane: {}
  spiffeID:
    trustDomain: konnect-demo.mesh.local
  provider:
    type: Bundled
    bundled:
      autogenerate:
        enabled: true
      insecureAllowSelfSigned: true
      meshTrustCreation: Enabled
---
type: MeshTrafficPermission
mesh: konnect-demo
name: client-to-server
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: server
  rules:
    - default:
        allow:
          - spiffeID:
              type: Exact
              value: spiffe://konnect-demo.mesh.local/ns/kong-mesh-demo/sa/client
EOF
```

`MeshIdentity` issues certificates and publishes their CA in `MeshTrust`. This example accepts
a generated self-signed CA for the demo; review your production PKI requirements before reusing
it. The identity's trust domain plus the Kubernetes namespace and ServiceAccount determine
the caller ID. Only that caller is allowed to reach proxies labelled `app: server`.

Wait for the identity's readiness conditions and generated trust before deploying workloads:

```sh
kongctl get mesh meshidentities demo-identity --mesh konnect-demo -o yaml \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
kongctl get mesh meshtrusts --mesh konnect-demo \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
```

## Deploy the test applications

The namespace labels select the mesh and enable sidecar injection. The server is a simple HTTP
destination. The client runs `curl` and has a dedicated ServiceAccount so its identity is explicit.

```sh
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: kong-mesh-demo
  labels:
    kuma.io/mesh: konnect-demo
    kuma.io/sidecar-injection: enabled
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: client
  namespace: kong-mesh-demo
---
apiVersion: v1
kind: Service
metadata:
  name: server
  namespace: kong-mesh-demo
spec:
  selector:
    app: server
  ports:
    - port: 80
      targetPort: 80
      appProtocol: http
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: server
  namespace: kong-mesh-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: server
  template:
    metadata:
      labels:
        app: server
    spec:
      containers:
        - name: server
          image: nginx:1.27.4
          ports:
            - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client
  namespace: kong-mesh-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: client
  template:
    metadata:
      labels:
        app: client
    spec:
      serviceAccountName: client
      containers:
        - name: client
          image: curlimages/curl:8.12.1
          command: ["sleep", "86400"]
EOF
kubectl -n kong-mesh-demo rollout status deployment/server --timeout=180s
kubectl -n kong-mesh-demo rollout status deployment/client --timeout=180s
```

## Verify an allowed and a denied call

Check that both workloads have ready mesh sidecars and that `server` has a generated
`MeshService`. Confirm their identities in the proxy inspection output:

```sh
kubectl -n kong-mesh-demo get pods
kongctl get mesh meshservices --mesh konnect-demo \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
kongctl get mesh inspect dataplanes --mesh konnect-demo \
  --control-plane-id "$CONTROL_PLANE_ID" --region "$KONNECT_REGION"
kubectl -n kong-mesh-demo exec deployment/client -c client -- \
  curl --fail --max-time 10 http://server.kong-mesh-demo.svc.cluster.local/
```

Expect the nginx welcome page. The request originates in the meshed client, so it exercises
the client-to-server mesh connection rather than a port-forward that bypasses it.

For a negative check, change only the client's ServiceAccount to `default`. Wait for the
replacement Pod, then repeat the same request:

```sh
kubectl -n kong-mesh-demo patch deployment client --type=merge \
  -p '{"spec":{"template":{"spec":{"serviceAccountName":"default"}}}}'
kubectl -n kong-mesh-demo rollout status deployment/client --timeout=180s
kubectl -n kong-mesh-demo exec deployment/client -c client -- \
  curl --fail --max-time 10 http://server.kong-mesh-demo.svc.cluster.local/
```

This caller's identity ends in `/sa/default`, which the permission does not allow. The request
must fail. Check the new caller identity and destination authorization diagnostics so an
unrelated connection failure is not mistaken for a successful permission test.

Restore the allowed identity and confirm the request succeeds again:

```sh
kubectl -n kong-mesh-demo patch deployment client --type=merge \
  -p '{"spec":{"template":{"spec":{"serviceAccountName":"client"}}}}'
kubectl -n kong-mesh-demo rollout status deployment/client --timeout=180s
kubectl -n kong-mesh-demo exec deployment/client -c client -- \
  curl --fail --max-time 10 http://server.kong-mesh-demo.svc.cluster.local/
```

Use the [MeshTrafficPermission reference](/mesh/policies/meshtrafficpermission/) if the observed
result differs. Before adding cross-zone or external-service traffic, configure the appropriate
[mesh-scoped zone proxies](/mesh/mesh-scoped-zone-proxies/).
