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
