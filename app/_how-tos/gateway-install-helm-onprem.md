---
title: Install {{ site.base_gateway }} on-prem with Helm
published: false
description: TODO
content_type: how_to
permalink: /gateway/install/kubernetes/on-prem/
breadcrumbs:
  - /gateway/
  - /gateway/install/

products:
  - gateway

works_on:
  - konnect
  - on-prem

entities: []

tldr: null

prereqs:
  skip_product: true

topology_switcher: page

---

## Helm Setup

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

## Create Certificates

```bash
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) -keyout ./tls.key -out ./tls.crt -days 1095 -subj "/CN=kong_clustering"
```

Create a Secret containing the certificate:

```bash
kubectl create namespace kong
kubectl create secret tls kong-cluster-cert --cert=./tls.crt --key=./tls.key -n kong
```


## Create a License

Create a license

## Create a Control Plane

TODO

```yaml
echo '
# Do not use Kong Ingress Controller
ingressController:
 enabled: false
  
image:
 repository: kong/kong-gateway
 tag: "{{ site.data.gateway_latest.release }}"
  
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
 pg_host: kong-cp-postgresql.kong.svc.cluster.local
 pg_ssl: "on"
  
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
  
# Optional features
manager:
 enabled: false
  
# These roles will be served by different Helm releases
proxy:
 enabled: false
' > values-cp.yaml
```

(Optional) If you want to deploy a Postgres database within the cluster for testing purposes, add the following to the bottom of values-cp.yaml.

```yaml
echo '
# This is for testing purposes only
# DO NOT DO THIS IN PRODUCTION
# Your cluster needs a way to create PersistentVolumeClaims
# if this option is enabled
postgresql:
  enabled: true
  auth:
    password: demo123
' >> values-cp.yaml
```

## Deploy a Data Plane

This is common

```yaml
echo '
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
  
admin:
 enabled: false
  
manager:
 enabled: false
' > values-dp.yaml
```

## Testing

Foo bar. Use deck apply to sync some example config