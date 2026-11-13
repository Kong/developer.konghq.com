1. To test your mesh, deploy the {{site.mesh_product_name}} demo app into the `kong-mesh-demo` namespace:
   
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
         - image: ghcr.io/kumahq/kuma-counter-demo:latest
           name: kv
           ports:
           - containerPort: 5050
             name: http
   " | kubectl apply -f -
   ```
   {:.collapsible}
   
1. Wait for the demo app to be ready:
   
   ```sh
   kubectl wait -n kong-mesh-demo --for=condition=available --timeout=120s deployment --all
   ```
   
   This creates:
   
   * `demo-app`: a counter web app on port 5050
   * `kv`: the key-value store that backs the counter
   