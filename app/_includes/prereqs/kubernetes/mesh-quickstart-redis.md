1. Install {{site.mesh_product_name}}:

   ```sh
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
     name: kuma-demo
     labels:
       kuma.io/sidecar-injection: enabled
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: redis
     namespace: kuma-demo
   spec:
     selector:
       matchLabels:
         app: redis
     replicas: 1
     template:
       metadata:
         labels:
           app: redis
       spec:
         containers:
           - name: redis
             image: 'redis'
             ports:
               - name: tcp
                 containerPort: 6379
             lifecycle:
               preStop: # delay shutdown to support graceful mesh leave
                 exec:
                   command: ['/bin/sleep', '30']
               postStart:
                 exec:
                   command:
                     - /bin/sh
                     - -c
                     - |
                       # wait until redis responds before setting the key
                       for i in $(seq 1 30); do
                         if /usr/local/bin/redis-cli ping >/dev/null 2>&1; then
                           /usr/local/bin/redis-cli set zone local && exit 0
                         fi
                         sleep 1
                       done
                       echo 'Redis not ready after 30s, skipping postStart'
                       exit 0
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: redis
     namespace: kuma-demo
     labels:
       app: redis
   spec:
     selector:
       app: redis
     ports:
     - protocol: TCP
       port: 6379
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: demo-app
     namespace: kuma-demo
   spec:
     selector:
       matchLabels:
         app: demo-app
     replicas: 1
     template:
       metadata:
         labels:
           app: demo-app
       spec:
         containers:
           - name: demo-app
             image: 'kumahq/kuma-demo'
             env:
               - name: REDIS_HOST
                 value: 'redis.kuma-demo.svc.cluster.local'
               - name: REDIS_PORT
                 value: '6379'
               - name: APP_VERSION
                 value: '1.0'
               - name: APP_COLOR
                 value: '#efefef'
             ports:
               - name: http
                 containerPort: 5000
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: demo-app
     namespace: kuma-demo
     labels:
       app: demo-app
   spec:
     selector:
       app: demo-app
     ports:
     - protocol: TCP
       appProtocol: http
       port: 5000" | kubectl apply -f -
   ```
