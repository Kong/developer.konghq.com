Run the following command to deploy a demo Service in a new `kong-mesh-demo-migration` namespace outside of the mesh:

```sh
echo "
apiVersion: v1
kind: Namespace
metadata:
  labels:
    kuma.io/sidecar-injection: disabled
  name: kong-mesh-demo-migration
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: kong-mesh-demo-migration
spec:
  ports:
  - appProtocol: http
    port: 5050
    protocol: TCP
    targetPort: 5050
  selector:
    app: demo-app
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app-v1
  namespace: kong-mesh-demo-migration
spec:
  ports:
  - appProtocol: http
    port: 5050
    protocol: TCP
    targetPort: 5050
  selector:
    app: demo-app
    version: v1
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app-v2
  namespace: kong-mesh-demo-migration
spec:
  ports:
  - appProtocol: http
    port: 5050
    protocol: TCP
    targetPort: 5050
  selector:
    app: demo-app
    version: v2
---
apiVersion: v1
kind: Service
metadata:
  name: kv
  namespace: kong-mesh-demo-migration
spec:
  ports:
  - appProtocol: http
    port: 5050
    protocol: TCP
    targetPort: 5050
  selector:
    app: kv
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: demo-app
    version: v1
  name: demo-app
  namespace: kong-mesh-demo-migration
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-app
      version: v1
  template:
    metadata:
      labels:
        app: demo-app
        version: v1
    spec:
      containers:
      - env:
        - name: OTEL_SERVICE_NAME
          value: demo-app
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: http://opentelemetry-collector.mesh-observability:4317
        - name: KV_URL
          value: http://kv.kong-mesh-demo-migration.svc.cluster.local:5050
        - name: APP_VERSION
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['version']
        image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:1472f3e1d7787a2a16af24f5deab7ab7e8316bb6076a8b42f634426d08cad0f8
        name: app
        ports:
        - containerPort: 5050
          name: http
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: demo-app
    version: v2
  name: demo-app-v2
  namespace: kong-mesh-demo-migration
spec:
  replicas: 0
  selector:
    matchLabels:
      app: demo-app
      version: v2
  template:
    metadata:
      labels:
        app: demo-app
        version: v2
    spec:
      containers:
      - env:
        - name: OTEL_SERVICE_NAME
          value: demo-app
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: http://opentelemetry-collector.mesh-observability:4317
        - name: KV_URL
          value: http://kv.kong-mesh-demo-migration.svc.cluster.local:5050
        - name: APP_VERSION
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['version']
        image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:1472f3e1d7787a2a16af24f5deab7ab7e8316bb6076a8b42f634426d08cad0f8
        name: demo-app
        ports:
        - containerPort: 5050
          name: http
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kv
  namespace: kong-mesh-demo-migration
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kv
  template:
    metadata:
      labels:
        app: kv
    spec:
      containers:
      - env:
        - name: OTEL_SERVICE_NAME
          value: kv
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: http://opentelemetry-collector.mesh-observability:4317
        - name: APP_VERSION
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['version']
        image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:1472f3e1d7787a2a16af24f5deab7ab7e8316bb6076a8b42f634426d08cad0f8
        name: app
        ports:
        - containerPort: 5050
          name: http" | kubectl apply -f -