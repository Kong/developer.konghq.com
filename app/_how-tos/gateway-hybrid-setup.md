---
title: Run {{site.base_gateway}} in Hybrid mode
content_type: how_to
permalink: /gateway/install/hybrid/

description: Configure separate Control Plane and Data Plane nodes using Hybrid mode and mTLS

breadcrumbs:
  - /gateway/
  - /gateway/install/

products:
  - gateway

works_on:
  - on-prem
tags:
  - install
tldr:
  q: How do I run {{ site.base_gateway }} in Hybrid mode?
  a: |
    Deploy {{ site.base_gateway }} twice, once with `role=control_plane` and once with `role=data_plane`.

    * The `kong.conf` file for the Control Plane must contain connection details for your database
    * The `kong.conf` file for the Data Plane must contain the Control Plane address, plus the `cluster_cert*` parameters


automated_tests: false

prereqs:
  skip_product: true
  inline:
    - title: Install {{site.base_gateway}}
      content: |
        {:.warning}
        > {{ site.base_gateway }} must be installed on both the Control Plane machine <u>and</u> the Data Plane machine before following this how-to.
         
        To find instructions for your operating system, see the [install {{site.base_gateway}}](/gateway/install/#linux) page.
    - title: Install PostgreSQL
      content: |
        {{ site.base_gateway }} requires a database to run in Hybrid mode. For this how-to, install PostgreSQL on the same node as your Control Plane.
        
        To bootstrap your database, follow the [configure a datastore how-to](/how-to/configure-datastore/).

        After setting up a database, set the following variables:

        ```bash
        export KONG_DATABASE=postgres
        export KONG_PG_HOST=127.0.0.1
        export KONG_PG_PORT=5432
        export KONG_PG_USER=kong
        export KONG_PG_PASSWORD=super_secret
        export KONG_PG_DATABASE=kong
        ```

faqs:
  - q: My Data Plane says "no Route matched with those values".
    a: |
      Wait 20 seconds then try again. If it continues to return this message, run `curl localhost:8001/clustering/data-planes` on the Control Plane node and check if the Data Plane is listed.
---

This how-to explains how to run {{ site.base_gateway }} on-prem in [hybrid mode](/gateway/hybrid-mode/). The quickest way to get started with hybrid mode is with {{ site.konnect_short_name }}.

{% include install/konnect-cta.html%}

If you prefer not to use {{ site.konnect_short_name }}, move on to the next step.
## Create clustering certificates

{{ site.base_gateway }} uses mTLS to secure the control plane/data plane communication when running in hybrid mode.

Generate a TLS certificate using OpenSSL on the Control Plane machine:

```bash
mkdir certs && cd certs
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) \
  -keyout ./tls.key -out ./tls.crt -days 1095 -subj "/CN=kong_clustering"
cd ..
sudo mv certs /etc/kong
sudo chown -R root:root /etc/kong/certs
```

## Deploy Kong as a Control Plane

Your Control Plane is the {{ site.base_gateway }} instance that manages configuration. Each Data Plane connects to the Control Plane using the certificates generated in the previous step to fetch its configuration.

To configure a {{ site.base_gateway }} instance as a Control Plane, run the following command on your Control Plane machine to configure the `kong.conf` file:

```bash
echo "
# This is a control_plane node
role = control_plane

# These certificates are used for control plane / data plane communication
cluster_cert = /etc/kong/certs/tls.crt
cluster_cert_key = /etc/kong/certs/tls.key

# Database connection
database = $KONG_DATABASE
pg_database = $KONG_PG_DATABASE
pg_user = $KONG_PG_USER
pg_port = $KONG_PG_PORT
pg_password = $KONG_PG_PASSWORD
pg_host = $KONG_PG_HOST
pg_ssl = \"on\"

# Use this to log in to Kong Manager
password = kong_admin_password
" | sudo tee /etc/kong/kong.conf
```

Finally, restart {{ site.base_gateway }}:

```bash
sudo kong restart
```

## Create an example Service and Route

Send the following `curl` requests on the Control Plane machine to configure a test Service and Route:

```bash
curl -i -X POST http://localhost:8001/services/ \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    --data '{
      "name": "example-service",
      "url": "http://httpbin.konghq.com"
    }'

curl -i -X POST http://localhost:8001/services/example-service/routes/ \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    --data '{
      "name": "example-route",
      "paths": [
        "/mock"
      ]
    }'
```

After configuring both machines, we'll use these entities to confirm that the Data Plane is configured correctly.

## Deploy Kong as a Data Plane

Your Data Plane uses the same certificates that were provided to the Control Plane to identify itself to the Control Plane. This is known as _pinned certificate_ authentication.

Copy the certificates from the Control Plane node into `/etc/kong/certs` on the Data Plane node.

{:.warning}
> The Data Plane will not be able to connect to the Control Plane unless the certificates are identical on both machines.

To connect to the Control Plane, we need to provide its address to the Data Plane. Replace `1.2.3.4` below with the IP address of your Control Plane, and run this command on your Data Plane machine:

```bash
export CONTROL_PLANE_IP="1.2.3.4"
```

Finally, configure {{ site.base_gateway }} to run as a `data_plane` using the following configuration. 
It contains a `role`, details on how to connect to the Control Plane, and which certificates to use for authentication.

Update `kong.conf` on your Data Plane:

```bash
echo "
# data_plane nodes do not have a database
role = data_plane
database = off

# Tell the data plane how to connect to the control plane
cluster_control_plane = $CONTROL_PLANE_IP:8005
cluster_telemetry_endpoint = $CONTROL_PLANE_IP:8006

# Configure control plane / data plane authentication
lua_ssl_trusted_certificate = /etc/kong/certs/tls.crt
cluster_cert = /etc/kong/certs/tls.crt
cluster_cert_key = /etc/kong/certs/tls.key
" | sudo tee /etc/kong/kong.conf
```

Start your Data Plane to connect it to the Control Plane:

```bash
sudo kong start
```

## Test your deployment

At this point, you have deployed and configured a Control Plane and attached a Data Plane to it. To make sure that the connection is working, run the following command on your _Data Plane_ node:

```sh
curl http://localhost:8000/mock/anything
```

This will return a JSON response containing information about the request:

```json
{
  "args": {}, 
  "data": "", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Accept": "*/*", 
    "Connection": "keep-alive", 
    "Host": "httpbin.konghq.com", 
    "User-Agent": "curl/8.5.0", 
    "X-Forwarded-Host": "localhost", 
    "X-Forwarded-Path": "/mock/anything", 
    "X-Forwarded-Prefix": "/mock", 
    "X-Kong-Request-Id": "86c96f45e619b55da600990abdfdac35"
  }, 
  "json": null, 
  "method": "GET", 
  "origin": "127.0.0.1", 
  "url": "http://localhost/anything"
}
```