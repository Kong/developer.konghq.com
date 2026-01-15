1. Install {{site.mesh_product_name}}:

   ```sh
   helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
   helm repo update
   helm upgrade \
     --install \
     --create-namespace \
     --namespace kong-mesh-system \
     kong-mesh kong-mesh/kong-mesh
   kubectl wait -n kong-mesh-system --for=condition=ready pod --selector=app=kong-mesh-control-plane --timeout=90s
   ```

1. Apply the demo configuration:

   ```sh
   echo "
   apiVersion: v1
   kind: Namespace
   metadata:
     labels:
       kuma.io/sidecar-injection: enabled
     name: kong-mesh-demo
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: demo-app
     namespace: kong-mesh-demo
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
     namespace: kong-mesh-demo
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
     namespace: kong-mesh-demo
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
     namespace: kong-mesh-demo
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
     namespace: kong-mesh-demo
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
             value: http://kv.kong-mesh-demo.svc.cluster.local:5050
           - name: APP_VERSION
             valueFrom:
               fieldRef:
                 fieldPath: metadata.labels['version']
           image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:daf8f5cffa10b576ff845be84e4e3bd5a8a6470c7e66293c5e03a148f08ac148
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
     namespace: kong-mesh-demo
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
             value: http://kv.kong-mesh-demo.svc.cluster.local:5050
           - name: APP_VERSION
             valueFrom:
               fieldRef:
                 fieldPath: metadata.labels['version']
           image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:daf8f5cffa10b576ff845be84e4e3bd5a8a6470c7e66293c5e03a148f08ac148
           name: demo-app
           ports:
           - containerPort: 5050
             name: http
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: kv
     namespace: kong-mesh-demo
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
           image: ghcr.io/kumahq/kuma-counter-demo:latest@sha256:daf8f5cffa10b576ff845be84e4e3bd5a8a6470c7e66293c5e03a148f08ac148
           name: app
           ports:
           - containerPort: 5050
             name: http
   ---
   apiVersion: kuma.io/v1alpha1
   kind: Mesh
   metadata:
     name: default
   spec:
     meshServices:
       mode: Exclusive
     mtls:
       backends:
       - name: ca-1
         type: builtin
       enabledBackend: ca-1
   ---
   apiVersion: kuma.io/v1alpha1
   kind: MeshTrafficPermission
   metadata:
     name: kv
     namespace: kong-mesh-demo
   spec:
     from:
     - default:
         action: Allow
       targetRef:
         kind: MeshSubset
         tags:
           app: demo-app
           k8s.kuma.io/namespace: kong-mesh-demo
     targetRef:
       kind: Dataplane
       labels:
         app: kv" | kubectl apply -f -
   ```
