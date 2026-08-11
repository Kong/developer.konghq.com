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
  - q: Why do I get a "self-signed certificate in certificate chain" error connecting to PostgreSQL?
    a: |
      This happens when `pg_ssl` is enabled but {{ site.base_gateway }} can't validate the database server's certificate, which is the case with the Cloud Native PostgreSQL operator's self-signed cluster certificates. `pg_ssl_verify` defaults to `on`, so {{ site.base_gateway }} validates the PostgreSQL server certificate against `lua_ssl_trusted_certificate`, which defaults to the system CA bundle and doesn't include a self-signed CA.

      To fix this, trust the CA certificate from the CNPG-generated secret (for example, `<cluster-name>-ca`):

      1. Extract the CA certificate from the CNPG-generated secret.

         ```bash
         kubectl get secret kong-cp-db-ca -n kong -o jsonpath='{.data.ca\.crt}' | base64 -d > cnpg-ca.crt
         ```

      1. Create a secret containing just that CA certificate, so it's separate from the CNPG-managed one.

         ```bash
         kubectl create secret generic kong-pg-ca --from-file=tls.crt=cnpg-ca.crt -n kong
         ```

      1. In `values-cp.yaml`, mount the secret and point {{ site.base_gateway }} at it.

         ```yaml
         secretVolumes:
           - kong-cluster-cert
           - kong-pg-ca

         env:
           pg_ssl: "on"
           lua_ssl_trusted_certificate: /etc/secrets/kong-pg-ca/tls.crt,system
         ```

      1. Apply the updated values file.

         ```bash
         helm upgrade kong-cp kong/kong -n kong --values ./values-cp.yaml
         ```

      {:.warning}
      > Setting `pg_ssl_verify` to `off` also avoids this error, but is discouraged as of {{ site.base_gateway }} 3.14, and can prevent {{ site.base_gateway }} from starting in newer minor versions.
prereqs:
  skip_product: true

topology_switcher: page

automated_tests: false

tags:
  - install
  - helm
---

These instructions configure {{ site.base_gateway }} to use separate control plane and data plane deployments. This is the recommended production installation method.

## Set up Helm

Kong provides a Helm chart for deploying {{ site.base_gateway }}. Add the `charts.konghq.com` repository and run `helm repo update` to ensure that you have the latest version of the chart.

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

## Create a {{ site.ee_product_name }} license

1. Create the `kong` namespace:

   ```bash
   kubectl create namespace kong
   ```

1. Create a {{site.ee_product_name}} license secret.

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

   ```bash
   kubectl create secret tls kong-cluster-cert --cert=./tls.crt --key=./tls.key -n kong
   ```

## Deploy a PostgreSQL database

If you want to deploy a PostgreSQL database within the cluster for testing purposes, you can install the Cloud Native PostgreSQL operator within your cluster.

1. Install the operator:

   ```bash
   helm repo add cnpg https://cloudnative-pg.github.io/charts
   helm upgrade --install cnpg \
     --namespace cnpg \
     --create-namespace \
     cnpg/cloudnative-pg

   kubectl wait --for=condition=Available deployment -l app.kubernetes.io/name=cloudnative-pg -n cnpg --timeout=90s
   ```

1. Create the database as well as a secret for the database:

   ```bash
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

## Create a control plane

The control plane contains all {{ site.base_gateway }} configurations. The configuration is stored in a PostgreSQL database.

1. Create a `values-cp.yaml` file, replacing `{{ site.data.gateway_latest.release }}` with your own version of {{site.base_gateway}}:

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
{:.collapsible}

{% endcapture %}

{{ values_file | indent }}

   {:.info}
   > The Cloud Native PostgreSQL operator generates a self-signed CA for the cluster's certificates. If you enable `pg_ssl` for the control plane's database connection, Kong validates this certificate by default and the connection fails with a `self-signed certificate in certificate chain` error unless you also trust the CA, as described in the [FAQ](#why-do-i-get-a-self-signed-certificate-in-certificate-chain-error-connecting-to-postgresql).

1. If you are using an existing, or external PostgreSQL database (recommended), update the database connection values in `values-cp.yaml`.

   - `env.pg_database`: The database name to use
   - `env.pg_user`: Your database username
   - `env.pg_password`: Your database password
   - `env.pg_host`: The hostname of your PostgreSQL database
   - `env.pg_ssl`: Use SSL to connect to the database

1. Set your Kong Manager super admin password in `values-cp.yaml`.

   - `env.password`: The Kong Manager super admin password

1. Run `helm install` to create the release.

   ```bash
   helm install kong-cp kong/kong -n kong --values ./values-cp.yaml
   ```

1. Run the following command to ensure that the control plane is running as expected:

   ```bash
   kubectl get pods -n kong
   ```
   
   You should see the control plane pod running:

   ```
   NAME                                 READY   STATUS
   kong-cp-kong-7bb77dfdf9-x28xf        1/1     Running
   ```
   {:.no-copy-code}

## Create a data plane

The {{ site.base_gateway }} data plane is responsible for processing incoming traffic. It receives the routing configuration from the control plane using the clustering endpoint.

1. Create a `values-dp.yaml` file.

{% capture values_file %}

```bash
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
  # `system` keeps the default system CA bundle trusted for proxied upstreams
  lua_ssl_trusted_certificate: /etc/secrets/kong-cluster-cert/tls.crt,system
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

1. Run the following command to ensure that the data plane is running as expected:

   ```bash
   kubectl get pods -n kong
   ```
   
   You should see the data plane pod running:
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
   echo $PROXY_IP
   ```

1. Make an HTTP request to your `$PROXY_IP`. This will return a `HTTP 404` served by {{ site.base_gateway }}:

   ```bash
   curl -i $PROXY_IP/mock/anything
   ```

1. In another terminal, run `kubectl port-forward` to set up port forwarding and access the Admin API:

   ```bash
   kubectl port-forward -n kong service/kong-cp-kong-admin 8001
   ```

1. Create a mock Service and Route:

   ```bash
   curl localhost:8001/services -d name=mock -d url="https://httpbin.konghq.com"
   curl localhost:8001/services/mock/routes -d "paths=/mock" -d "protocols[]=http"
   ```

1. Make an HTTP request to your `$PROXY_IP` again. This time {{ site.base_gateway }} will route the request to httpbin:

   ```bash
   curl -i $PROXY_IP/mock/anything
   ```

## Terminate TLS at the proxy

By default, the data plane serves a built-in {{ site.base_gateway }} certificate for HTTPS traffic. To present your own certificate for a hostname, generate a certificate, mount it into the data plane, and tell {{ site.base_gateway }} which certificate and key to load.

The proxy TLS certificate is a second secret, mounted alongside the clustering certificate you created earlier.

### Generate a TLS certificate

{% include /k8s/create-certificate.md namespace='kong' hostname='demo.example.com' secret_name='demo-example-com' cert_required=true %}

{:.info}
> The secret name can't contain dots. The Helm chart uses each `secretVolumes` entry as a Kubernetes volume name, and volume names must be a DNS label. This is why the secret is named `demo-example-com` rather than matching the `demo.example.com` hostname exactly.

### Load the certificate on the data plane

1. In `values-dp.yaml`, add the certificate secret to `secretVolumes` and set `ssl_cert` and `ssl_cert_key` in `env`:

   ```yaml
   # Mount the clustering cert and the proxy TLS cert
   secretVolumes:
     - kong-cluster-cert
     - demo-example-com

   env:
     # Serve this certificate for proxy HTTPS traffic
     ssl_cert: /etc/secrets/demo-example-com/tls.crt
     ssl_cert_key: /etc/secrets/demo-example-com/tls.key
   ```

   `secretVolumes` mounts each secret at `/etc/secrets/<secret-name>/`, so the certificate you created in the previous step is at `/etc/secrets/demo-example-com/tls.crt` and `/etc/secrets/demo-example-com/tls.key`.

1. Apply the updated values file:

   ```bash
   helm upgrade kong-dp kong/kong -n kong --values ./values-dp.yaml
   ```

1. Verify that the proxy serves your certificate over HTTPS. Use `-v` to print the certificate the proxy presents, and `-k` to accept it, because this is a self-signed test certificate:

   ```bash
   curl -skv -o /dev/null https://$PROXY_IP/mock/anything 2>&1 | grep -E "subject:|issuer:"
   ```

   You should see your certificate rather than the built-in {{ site.base_gateway }} default:

   ```text
   *   subject: CN=demo.example.com
   *   issuer: CN=demo.example.com
   ```

   {:.info}
   > `ssl_cert` sets the default certificate for the proxy listener, so {{ site.base_gateway }} presents it on every HTTPS connection, whatever hostname the client requests. To serve different certificates per hostname, create [Certificate](/gateway/entities/certificate/) and [SNI](/gateway/entities/sni/) entities instead.
