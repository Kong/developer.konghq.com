This guide starts from a hybrid {{site.base_gateway}} in the `kong-dr` cluster: a PostgreSQL database, a control plane, a data plane, and one Gateway Service and Route.

1. Add the Kong Helm charts:

   ```bash
   helm repo add kong https://charts.konghq.com
   ```

1. Update the Helm repositories:

   ```bash
   helm repo update
   ```

1. Create the `kong` namespace:

   ```bash
   kubectl create namespace kong
   ```

1. Store the license in a Secret:

   ```bash
   kubectl create secret generic kong-enterprise-license -n kong --from-file=license=license.json
   ```

1. Create the certificate and key that the control plane and the data plane use to authenticate each other:

   ```bash
   openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
     -keyout ./tls.key -out ./tls.crt -days 1095 -subj "/CN=kong_clustering"
   ```

1. Store the certificate and key in a Secret:

   ```bash
   kubectl create secret tls kong-cluster-cert -n kong --cert=./tls.crt --key=./tls.key
   ```

1. Create a manifest for a PostgreSQL database named `kong-db`:

   ```bash
   cat <<'EOF' > postgres.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: kong-db
     namespace: kong
   spec:
     selector:
       matchLabels:
         app: kong-db
     template:
       metadata:
         labels:
           app: kong-db
       spec:
         containers:
         - name: postgres
           image: postgres:17
           env:
           - name: POSTGRES_USER
             value: kong
           - name: POSTGRES_PASSWORD
             value: kong
           - name: POSTGRES_DB
             value: kong
           ports:
           - containerPort: 5432
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: kong-db
     namespace: kong
   spec:
     selector:
       app: kong-db
     ports:
     - port: 5432
   EOF
   ```

1. Deploy the database:

   ```bash
   kubectl apply -f postgres.yaml
   ```

1. Wait for the database:

   ```bash
   kubectl rollout status deployment/kong-db -n kong --timeout=300s
   ```

1. Create a `values-cp.yaml` file for the control plane:

   ```bash
   cat <<'EOF' > values-cp.yaml
   ingressController:
     enabled: false
   image:
     repository: kong/kong-gateway
     tag: "{{ site.data.gateway_latest.release }}"
   secretVolumes:
     - kong-cluster-cert
   env:
     role: control_plane
     cluster_cert: /etc/secrets/kong-cluster-cert/tls.crt
     cluster_cert_key: /etc/secrets/kong-cluster-cert/tls.key
     database: postgres
     pg_host: kong-db.kong.svc.cluster.local
     pg_user: kong
     pg_password: kong
     pg_database: kong
   enterprise:
     enabled: true
     license_secret: kong-enterprise-license
   admin:
     enabled: true
     http:
       enabled: true
   cluster:
     enabled: true
     tls:
       enabled: true
   clustertelemetry:
     enabled: true
     tls:
       enabled: true
   proxy:
     enabled: false
   manager:
     enabled: false
   EOF
   ```

1. Install the control plane:

   ```bash
   helm install kong-cp kong/kong -n kong -f values-cp.yaml --wait --timeout 5m
   ```

1. Forward the Admin API port of the control plane in the background:

   ```bash
   kubectl port-forward -n kong service/kong-cp-kong-admin 8001 > /dev/null 2>&1 &
   ```

1. Create a [Gateway Service](/gateway/entities/service/) named `dr-check` that points to an upstream:

   ```bash
   curl -X POST localhost:8001/services \
     -d name=dr-check -d url="https://httpbin.konghq.com"
   ```

1. Create a [Route](/gateway/entities/route/) named `dr-check` for the `/dr-check` path.
   New Routes accept only HTTPS by default, so set `protocols` to accept HTTP.
   Create the Route before you install the data plane, because a DB-less data plane passes its readiness check only after it receives a configuration with at least one Route:

   ```bash
   curl -X POST localhost:8001/services/dr-check/routes \
     -d name=dr-check -d "paths[]=/dr-check" -d "protocols[]=http"
   ```

1. Create a `values-dp.yaml` file that connects the data plane to the control plane:

   ```bash
   cat <<'EOF' > values-dp.yaml
   ingressController:
     enabled: false
   image:
     repository: kong/kong-gateway
     tag: "{{ site.data.gateway_latest.release }}"
   secretVolumes:
     - kong-cluster-cert
   env:
     role: data_plane
     database: "off"
     cluster_control_plane: kong-cp-kong-cluster.kong.svc.cluster.local:8005
     cluster_telemetry_endpoint: kong-cp-kong-clustertelemetry.kong.svc.cluster.local:8006
     lua_ssl_trusted_certificate: /etc/secrets/kong-cluster-cert/tls.crt,system
     cluster_cert: /etc/secrets/kong-cluster-cert/tls.crt
     cluster_cert_key: /etc/secrets/kong-cluster-cert/tls.key
   enterprise:
     enabled: true
     license_secret: kong-enterprise-license
   proxy:
     enabled: true
   admin:
     enabled: false
   manager:
     enabled: false
   EOF
   ```

1. Install the data plane:

   ```bash
   helm install kong-dp kong/kong -n kong -f values-dp.yaml --wait --timeout 5m
   ```
