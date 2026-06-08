Install {{site.mesh_product_name}}, configure the mesh, and deploy the Kong Air services this path builds on.

### Step 1: Install {{site.mesh_product_name}}

{% navtabs "install-mesh" %}
{% navtab "Kubernetes" %}
Add the Helm chart repository and install the control plane:

```bash
helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
helm repo update
helm upgrade --install \
  --create-namespace \
  --namespace kong-mesh-system \
  kong-mesh kong-mesh/kong-mesh
kubectl wait -n kong-mesh-system \
  --for=condition=ready pod \
  --selector=app=kong-mesh-control-plane \
  --timeout=120s
```
{% endnavtab %}
{% navtab "Universal" %}
Download the {{site.mesh_product_name}} binaries and start a standalone control plane:

```bash
curl -L https://developer.konghq.com/mesh/installer.sh | VERSION={{site.data.mesh_latest.version}} sh -
export PATH=$PATH:$(pwd)/{{site.mesh_product_name_path}}-{{site.data.mesh_latest.version}}/bin
kuma-cp run &
kumactl config control-planes add \
  --name default \
  --address grpcs://localhost:5678
```

The Universal steps in this path assume you register Data Plane proxies yourself using `kuma-dp run`. See the [Universal quickstart](/mesh/get-started-universal/) for the pattern.
{% endnavtab %}
{% endnavtabs %}

### Step 2: Configure the Mesh resource

The `Mesh` resource is the top-level configuration object. Set `meshServices.mode: Exclusive` so {{site.mesh_product_name}} requires explicit `MeshService` resources instead of auto-discovering services — this is what the traffic-splitting exercise in Step 4 depends on. mTLS is not enabled here; you'll add it in Step 2.

{% navtabs "configure-mesh" %}
{% navtab "Kubernetes (Global CP)" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  meshServices:
    mode: Exclusive' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal (Global CP)" %}
```bash
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

Apply a mesh-wide `allow-all` traffic permission so all services can communicate freely while you explore the architecture. Step 2 of this path removes it and replaces it with a default-deny posture.

{% navtabs "allow-all" %}
{% navtab "Kubernetes" %}
```bash
echo 'apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  name: allow-all
  namespace: kong-mesh-system
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow' | kubectl apply -f -
```
{% endnavtab %}
{% navtab "Universal" %}
```bash
echo 'type: MeshTrafficPermission
name: allow-all
mesh: default
spec:
  targetRef:
    kind: Mesh
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow' | kumactl apply -f -
```
{% endnavtab %}
{% endnavtabs %}

### Step 3: Deploy the Kong Air services

Create the `kong-air-production` namespace with sidecar injection enabled, then deploy all four Kong Air services used in this path:

| Service | Used in |
|---|---|
| `check-in-api` | Step 2 — target of mTLS and zero-trust policies |
| `flight-control` | Step 2 — authorized caller of `check-in-api` |
| `passenger-portal` | Steps 2, 4, 5 — blocked caller; source of booking-engine routes |
| `booking-engine` | Steps 4, 5 — has `v1` and `v2` variants for the traffic-split exercise |

`check-in-api`, `passenger-portal`, and `booking-engine` are labelled `region: us-east-1`. `flight-control` is labelled `region: us-west-2`. The Step 5 exercise applies a `MeshSubset` policy that targets `region: us-east-1` so you can confirm it does not affect `flight-control`.

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: kong-air-production
  labels:
    kuma.io/sidecar-injection: enabled
---
apiVersion: v1
kind: Service
metadata:
  name: check-in-api
  namespace: kong-air-production
spec:
  ports:
    - appProtocol: http
      port: 5050
      targetPort: 5050
  selector:
    app: check-in-api
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: check-in-api
  namespace: kong-air-production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: check-in-api
  template:
    metadata:
      labels:
        app: check-in-api
        region: us-east-1
    spec:
      containers:
        - name: app
          image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:daf8f5cffa10b576ff845be84e4e3bd5a8a6470c7e66293c5e03a148f08ac148
          ports:
            - containerPort: 5050
              name: http
          env:
            - name: APP_VERSION
              value: v1
---
apiVersion: v1
kind: Service
metadata:
  name: flight-control
  namespace: kong-air-production
spec:
  ports:
    - appProtocol: http
      port: 5050
      targetPort: 5050
  selector:
    app: flight-control
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flight-control
  namespace: kong-air-production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flight-control
  template:
    metadata:
      labels:
        app: flight-control
        region: us-west-2
    spec:
      containers:
        - name: app
          image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:daf8f5cffa10b576ff845be84e4e3bd5a8a6470c7e66293c5e03a148f08ac148
          ports:
            - containerPort: 5050
              name: http
          env:
            - name: APP_VERSION
              value: v1
            - name: KV_URL
              value: http://check-in-api.kong-air-production.svc.cluster.local:5050
---
apiVersion: v1
kind: Service
metadata:
  name: passenger-portal
  namespace: kong-air-production
spec:
  ports:
    - appProtocol: http
      port: 5050
      targetPort: 5050
  selector:
    app: passenger-portal
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: passenger-portal
  namespace: kong-air-production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: passenger-portal
  template:
    metadata:
      labels:
        app: passenger-portal
        region: us-east-1
    spec:
      containers:
        - name: app
          image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:daf8f5cffa10b576ff845be84e4e3bd5a8a6470c7e66293c5e03a148f08ac148
          ports:
            - containerPort: 5050
              name: http
          env:
            - name: APP_VERSION
              value: v1
            - name: KV_URL
              value: http://booking-engine.kong-air-production.svc.cluster.local:5050
---
# booking-engine: one shared Service + two versioned Services for the Step 4 traffic split.
# The v1 Deployment starts with 2 replicas; v2 starts at 0 and is scaled up in Step 4.
apiVersion: v1
kind: Service
metadata:
  name: booking-engine
  namespace: kong-air-production
spec:
  ports:
    - appProtocol: http
      port: 5050
      targetPort: 5050
  selector:
    app: booking-engine
---
apiVersion: v1
kind: Service
metadata:
  name: booking-engine-v1
  namespace: kong-air-production
spec:
  ports:
    - appProtocol: http
      port: 5050
      targetPort: 5050
  selector:
    app: booking-engine
    version: v1
---
apiVersion: v1
kind: Service
metadata:
  name: booking-engine-v2
  namespace: kong-air-production
spec:
  ports:
    - appProtocol: http
      port: 5050
      targetPort: 5050
  selector:
    app: booking-engine
    version: v2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: booking-engine
  namespace: kong-air-production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: booking-engine
      version: v1
  template:
    metadata:
      labels:
        app: booking-engine
        version: v1
        region: us-east-1
    spec:
      containers:
        - name: app
          image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:daf8f5cffa10b576ff845be84e4e3bd5a8a6470c7e66293c5e03a148f08ac148
          ports:
            - containerPort: 5050
              name: http
          env:
            - name: APP_VERSION
              value: v1
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: booking-engine-v2
  namespace: kong-air-production
spec:
  replicas: 0
  selector:
    matchLabels:
      app: booking-engine
      version: v2
  template:
    metadata:
      labels:
        app: booking-engine
        version: v2
        region: us-east-1
    spec:
      containers:
        - name: app
          image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:daf8f5cffa10b576ff845be84e4e3bd5a8a6470c7e66293c5e03a148f08ac148
          ports:
            - containerPort: 5050
              name: http
          env:
            - name: APP_VERSION
              value: v2
EOF
kubectl wait -n kong-air-production \
  --for=condition=available \
  --timeout=120s \
  deployment --all
```

### Step 4: Verify the setup

Confirm the control plane is running:

{% navtabs "verify-cp" %}
{% navtab "Kubernetes" %}
```bash
kubectl get pods -n kong-mesh-system
```

You should see a `kong-mesh-control-plane-*` pod in `Running` state.
{% endnavtab %}
{% navtab "Universal" %}
```bash
kumactl config control-planes list
```

The active CP is marked with `*`.
{% endnavtab %}
{% endnavtabs %}

Confirm sidecars are injected — each pod in `kong-air-production` should show `2/2` containers:

```bash
kubectl get pods -n kong-air-production
```

Inspect the `Mesh` resource to confirm `meshServices.mode: Exclusive` is set and there is no `mtls` block yet:

```bash
kubectl get mesh default -o yaml
```

Verify the `allow-all` permission is in place:

```bash
kubectl get meshtrafficpermissions -n kong-mesh-system
```

### What you set up

Your environment now has:

- **{{site.mesh_product_name}} control plane** in `kong-mesh-system`
- **`default` Mesh** with `meshServices.mode: Exclusive` — required for the MeshService routing in Steps 4 and 5
- **`allow-all` traffic permission** — Step 2 deletes this and replaces it with a default-deny posture
- **Kong Air services** in `kong-air-production`, all with sidecars injected:
  - `check-in-api` — 2 replicas, `region: us-east-1`
  - `flight-control` — 1 replica, `region: us-west-2`
  - `passenger-portal` — 1 replica, `region: us-east-1`
  - `booking-engine` — 2 replicas of `v1`, 0 replicas of `v2`, `region: us-east-1`

In Step 2 you'll enable mTLS on the `default` Mesh and replace the permissive baseline with a zero-trust default-deny posture.
