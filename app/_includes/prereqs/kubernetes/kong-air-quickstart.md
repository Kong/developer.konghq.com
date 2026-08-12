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

1. Create the `kong-air-mesh` mesh in `Exclusive` mode and deploy the Kong Air demo applications. The `passenger-portal`, `check-in-api`, and `flight-control` services each run in the `kong-air-production` namespace with their own service account, so every workload receives a distinct SPIFFE identity:

   ```sh
   kubectl apply -f - <<'EOF'
   apiVersion: kuma.io/v1alpha1
   kind: Mesh
   metadata:
     name: kong-air-mesh
   spec:
     meshServices:
       mode: Exclusive
   ---
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
     name: passenger-portal
     namespace: kong-air-production
   ---
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: check-in-api
     namespace: kong-air-production
   ---
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: flight-control
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
     name: passenger-portal
     namespace: kong-air-production
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: passenger-portal
         version: v1
     template:
       metadata:
         labels:
           app: passenger-portal
           version: v1
       spec:
         serviceAccountName: passenger-portal
         containers:
           - name: passenger-portal
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
     name: passenger-portal
     namespace: kong-air-production
   spec:
     selector:
       app: passenger-portal
     ports:
       - port: 8080
         targetPort: 8080
         name: http
         appProtocol: http
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: check-in-api
     namespace: kong-air-production
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: check-in-api
         version: v1
     template:
       metadata:
         labels:
           app: check-in-api
           version: v1
       spec:
         serviceAccountName: check-in-api
         containers:
           - name: check-in-api
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
     name: check-in-api
     namespace: kong-air-production
   spec:
     selector:
       app: check-in-api
     ports:
       - port: 8080
         targetPort: 8080
         name: http
         appProtocol: http
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
         version: v1
     template:
       metadata:
         labels:
           app: flight-control
           version: v1
       spec:
         serviceAccountName: flight-control
         containers:
           - name: flight-control
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
     name: flight-control
     namespace: kong-air-production
   spec:
     selector:
       app: flight-control
     ports:
       - port: 8080
         targetPort: 8080
         name: http
         appProtocol: http
   EOF
   kubectl wait -n kong-air-production --for=condition=available --timeout=120s deployment --all
   ```
   {:.collapsible}
