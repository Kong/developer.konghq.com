---
title: Install {{ site.base_gateway }} on-prem with Helm
short_title: Install {{ site.base_gateway }}
description: Deploy {{ site.base_gateway }} on Kubernetes in Hybrid mode
content_type: how_to
permalink: /gateway/install/kubernetes/on-prem/
breadcrumbs:
  - /gateway/
  - /gateway/install/
series:
  id: gateway-k8s-on-prem-install
  position: 1

products:
  - gateway

works_on:
  - konnect
  - on-prem

entities: []

tldr: null
faqs:
  - q: Can I install {{ site.base_gateway }} via Helm without cluster permissions?
    a: |
      Yes. Using the `kong` chart, set `ingressController.rbac.enableClusterRoles` to false. 

      {:.danger}
      > **Warning:** Some resources require a ClusterRole for reconciliation because the controllers need to watch cluster scoped resources. Disabling ClusterRoles causes them fail, so you need to disable the controllers when setting it to `false`. These resources include:
      > - All Gateway API resources
      > - `IngressClass`
      > - `KNative/Ingress` (KIC 2.x only)
      > - `KongClusterPlugin`
      > - `KongVault`, `KongLicense` (KIC 3.1 and above)
prereqs:
  skip_product: true

topology_switcher: page

automated_tests: false

tags:
  - install
  - helm
---

These instructions configure {{ site.base_gateway }} to use separate control plane and data plane deployments. This is the recommended production installation method.

## Helm Setup

Kong provides a Helm chart for deploying {{ site.base_gateway }}. Add the `charts.konghq.com` repository and run `helm repo update` to ensure that you have the latest version of the chart.

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

## Create a {{ site.ee_product_name }} License

First, create the `kong` namespace:

```bash
kubectl create namespace kong
```

Next, create a {{site.ee_product_name}} license secret.

{:.warning}
> Ensure you are in the directory that contains a `license.json` file before running this command.

```bash
kubectl create secret generic kong-enterprise-license --from-file=license=license.json -n kong
```

## Create clustering certificates

{{ site.base_gateway }} uses mTLS to secure the control plane/data plane communication when running in hybrid mode.

1. Generate a TLS certificate using OpenSSL.

   ```bash
   openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
     -keyout ./tls.key -out ./tls.crt -days 1095 -subj "/CN=kong_clustering"
   ```

1. Create a Kubernetes secret containing the certificate.

   ```
   kubectl create secret tls kong-cluster-cert --cert=./tls.crt --key=./tls.key -n kong
   ```

## Postgres database

If you want to deploy a Postgres database within the cluster for testing purposes, you can install the Cloud Native Postgres operator within your cluster.

```sh
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg \
  --namespace cnpg \
  --create-namespace \
  cnpg/cloudnative-pg
```

Once the operator is installed, create the database as well as a secret for the database:

```sh
echo 'apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: kong-cp-db
  namespace: kong
spec:
  instances: 1

  bootstrap:
    initdb:
      database: kong
      owner: kong
      secret:
        name: kong-db-secret

  storage:
    size: 10Gi
---
apiVersion: v1
kind: Secret
metadata:
  name: kong-db-secret
  namespace: kong
type: Opaque
stringData:
  username: kong
  password: demo123' | kubectl apply -f -
```


## Create a Control Plane

The control plane contains all {{ site.base_gateway }} configurations. The configuration is stored in a PostgreSQL database.

1. Create a `values-cp.yaml` file.

{% capture values_file %}

```yaml
echo '
# Do not use {{ site.kic_product_name }}
ingressController:
  enabled: false

image:
  repository: kong/kong-gateway
  tag: "'{{ site.data.gateway_latest.release }}'"

# Mount the secret created earlier
secretVolumes:
  - kong-cluster-cert

env:
  # This is a control_plane node
  role: control_plane
  # These certificates are used for control plane / data plane communication
  cluster_cert: /etc/secrets/kong-cluster-cert/tls.crt
  cluster_cert_key: /etc/secrets/kong-cluster-cert/tls.key

  # Database
  # CHANGE THESE VALUES
  database: postgres
  pg_database: kong
  pg_user: kong
  pg_password: demo123
  pg_host: kong-cp-db-rw.kong.svc.cluster.local
  pg_ssl: "on"
  pg_ssl_version: tlsv1_3        # <- this is KONG_PG_SSL_VERSION

  # Kong Manager password
  password: kong_admin_password

# Enterprise functionality
enterprise:
  enabled: true
  license_secret: kong-enterprise-license

# The control plane serves the Admin API
admin:
  enabled: true
  http:
    enabled: true

# Clustering endpoints are required in hybrid mode
cluster:
  enabled: true
  tls:
    enabled: true

clustertelemetry:
  enabled: true
  tls:
    enabled: true

manager:
  enabled: false

# These roles will be served by different Helm releases
proxy:
  enabled: false
' > values-cp.yaml
```

{% endcapture %}

{{ values_file | indent }}

1. If you are using an existing, or external Postgres database (recommended), update the database connection values in `values-cp.yaml`.

   - `env.pg_database`: The database name to use
   - `env.pg_user`: Your database username
   - `env.pg_password`: Your database password
   - `env.pg_host`: The hostname of your Postgres database
   - `env.pg_ssl`: Use SSL to connect to the database

1. Set your Kong Manager super admin password in `values-cp.yaml`.

   - `env.password`: The Kong Manager super admin password

1. Run `helm install` to create the release.

   ```bash
   helm install kong-cp kong/kong -n kong --values ./values-cp.yaml
   ```

1. Run `kubectl get pods -n kong`. Ensure that the control plane is running as expected.

   ```
   NAME                                 READY   STATUS
   kong-cp-kong-7bb77dfdf9-x28xf        1/1     Running
   ```
   {:.no-copy-code}

## Create a Data Plane

The {{ site.base_gateway }} data plane is responsible for processing incoming traffic. It receives the routing configuration from the control plane using the clustering endpoint.

1. Create a `values-dp.yaml` file.

{% capture values_file %}

```sh
echo '
# Do not use {{ site.kic_product_name }}
ingressController:
  enabled: false

image:
  repository: kong/kong-gateway
  tag: "{{ site.data.gateway_latest.release }}"

# Mount the secret created earlier
secretVolumes:
  - kong-cluster-cert

env:
  # data_plane nodes do not have a database
  role: data_plane
  database: "off"

  # Tell the data plane how to connect to the control plane
  cluster_control_plane: kong-cp-kong-cluster.kong.svc.cluster.local:8005
  cluster_telemetry_endpoint: kong-cp-kong-clustertelemetry.kong.svc.cluster.local:8006

  # Configure control plane / data plane authentication
  lua_ssl_trusted_certificate: /etc/secrets/kong-cluster-cert/tls.crt
  cluster_cert: /etc/secrets/kong-cluster-cert/tls.crt
  cluster_cert_key: /etc/secrets/kong-cluster-cert/tls.key

# Enterprise functionality
enterprise:
  enabled: true
  license_secret: kong-enterprise-license

# The data plane handles proxy traffic only
proxy:
  enabled: true

# These roles are served by the kong-cp deployment
admin:
  enabled: false

manager:
  enabled: false
' > ./values-dp.yaml
```

{% endcapture %}

{{ values_file | indent }}

1. Run `helm install` to create the release:

   ```bash
   helm install kong-dp kong/kong -n kong --values ./values-dp.yaml
   ```

1. Run `kubectl get pods -n kong` to ensure that the Data Plane is running as expected:

   ```
   NAME                                 READY   STATUS
   kong-dp-kong-5dbcd9f6b9-f2w49        1/1     Running
   ```
   {:.no-copy-code}

## Test your deployment

{{ site.base_gateway }} is now running. To send some test traffic, try the following:

1. Fetch the `LoadBalancer` address for the `kong-dp` service and store it in the `PROXY_IP` environment variable:

   ```bash
   PROXY_IP=$(kubectl get service --namespace kong kong-dp-kong-proxy \
     -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
   ```

1. Make an HTTP request to your `$PROXY_IP`. This will return a `HTTP 404` served by {{ site.base_gateway }}:

   ```bash
   curl $PROXY_IP/mock/anything
   ```

1. In another terminal, run `kubectl port-forward` to set up port forwarding and access the Admin API:

   ```bash
   kubectl port-forward -n kong service/kong-cp-kong-admin 8001
   ```

1. Create a mock Service and Route:

   ```bash
   curl localhost:8001/services -d name=mock -d url="https://httpbin.konghq.com"
   curl localhost:8001/services/mock/routes -d "paths=/mock"
   ```

1. Make an HTTP request to your `$PROXY_IP` again. This time {{ site.base_gateway }} will route the request to httpbin:

   ```bash
   curl $PROXY_IP/mock/anything
   ```
