---
title: How to setup a PKI Hybrid instance in Kubernetes with certificate manager
content_type: support
description: How to configure {{site.base_gateway}} Hybrid mode to use PKI mutual TLS with certificates issued by cert-manager and a private CA in Kubernetes.
products:
  - gateway
  - kic
works_on:
  - on-prem
  - konnect
related_resources:
  - text: "cert-manager Kubernetes installation documentation"
    url: "https://cert-manager.io/docs/installation/kubectl/"
tldr:
  q: How do I configure Kong Gateway Hybrid mode to use PKI certificates issued by a private CA with cert-manager in Kubernetes?
  a: |
    Use `cert-manager` to build a certificate chain from a private root CA through two intermediate CAs, then issue separate control plane (`server auth`) and data plane (`client auth`) certificates from the final intermediate issuer. Mount the resulting secrets into the Kong Helm chart values (`cluster_ca_cert`, `cluster_cert`, `cluster_cert_key`), set `cluster_mtls: pki` on both nodes, and set `lua_ssl_verify_depth` high enough to cover the full chain.
---

## Overview

There is a requirement to use cert-manager and a Private CA when setting up Kong in Hybrid mode with PKI certificates. As the certificates are not from a trusted CA, what configuration is needed to allow Kong to use the Private CA certificates?

## Steps

### Introduction

The steps below provide a walkthrough of the necessary configuration. This article assumes that you will be using a Private Root CA and 2 intermediate certificates, and that you have access to the Root CA private key and public certificate. For the purposes of this article, we will be assuming the below certificates are available;

`rootCA.key` - The Root CA private key

`rootCA.pem` - The Root CA Public certificate

It may be that in your environment, you do not have access to this certificate pair and maybe have a `ClusterIssuer` in cert-manager that you can use. You will need to adjust the instructions as appropriate for your environment.

### Install cert-manager

Follow the Kubernetes documentation to install and test cert-manager.

### Create the certificate chain

#### Create a secret for the RootCA

Create a `tls` secret that contains the Private Key and Public certificate for the Root CA

```bash

kubectl create secret tls rootca-key-pair --key="rootCA-noenc.key" --cert="rootCA.pem" -n kong
```

#### Create Root CA Issuer

```bash

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: rootca-issuer
  namespace: kong
spec:
  ca:
    secretName: rootca-key-pair
EOF
```

#### Create Intermediate 1 CA from Root CA Issuer

```bash

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: intermediate-ca1
  namespace: kong
spec:
  # Secret names are always required.
  secretName: intermediate-ca1-key-pair
  duration: 1440h # 60d
  renewBefore: 240h # 10d
  commonName: Kong Intermediate 1 CA
  isCA: true
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  # Issuer references are always required.
  issuerRef:
    name: rootca-issuer
    # We can reference ClusterIssuers by changing the kind here.
    # The default value is Issuer (i.e. a locally namespaced Issuer)
    kind: Issuer
    # This is optional since cert-manager will default to this value however
    # if you are using an external issuer, change this to that issuer group.
    group: cert-manager.io
EOF
```

#### Create Intermediate 1 CA Issuer

```bash

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: intermediate1ca-issuer
  namespace: kong
spec:
  ca:
    secretName: intermediate-ca1-key-pair
EOF
```

#### Create Intermediate 2 CA from Intermediate 1 CA Issuer

```bash

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: intermediate-ca2
  namespace: kong
spec:
  # Secret names are always required.
  secretName: intermediate-ca2-key-pair
  duration: 720h # 30d
  renewBefore: 120h # 5d
  commonName: Kong Intermediate 2 CA
  isCA: true
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  # Issuer references are always required.
  issuerRef:
    name: intermediate1ca-issuer
    # We can reference ClusterIssuers by changing the kind here.
    # The default value is Issuer (i.e. a locally namespaced Issuer)
    kind: Issuer
    # This is optional since cert-manager will default to this value however
    # if you are using an external issuer, change this to that issuer group.
    group: cert-manager.io
EOF
```

#### Create Intermediate 2 CA Issuer

```bash

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: intermediate2ca-issuer
  namespace: kong
spec:
  ca:
    secretName: intermediate-ca2-key-pair
EOF
```

#### Create a secret containing the full certificate chain

For certificate verification, it is necessary to provide the full chain from rootCA --> Intermediate1CA --> Intermediate2CA. This needs to be created as a `generic` secret

```bash

kubectl get secret rootca-key-pair -n kong -o jsonpath='{.data.tls\.crt}'|base64 -d > chain.pem
kubectl get secret intermediate-ca1-key-pair -n kong -o jsonpath='{.data.tls\.crt}'|base64 -d >> chain.pem
kubectl get secret intermediate-ca2-key-pair -n kong -o jsonpath='{.data.tls\.crt}'|base64 -d >> chain.pem
kubectl -n kong create secret generic cluster-fullchain --from-file=./chain.pem
```

### Create the Kong Cluster certificates

For PKI mode, the Control plane and Data plane need their own certificates that are signed by the same CA.

#### Create the Control Plane certificate pair

Create the cert-manager configuration which creates the control plane certificate. Note, the Control plane needs the "Web Server Authentication" usage;

```bash

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kong-control-plane-kong-cluster-inter
  namespace: kong
spec:
  # Secret names are always required.
  secretName: kong-control-plane-kong-cluster-inter
  duration: 240h # 10d
  renewBefore: 48h # 2d
  commonName: kong-cp
  subject:
    organizations:
    - kong-cp
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  usages:
    - server auth
  # At least one of a DNS Name, URI, or IP address is required.
  dnsNames:
  - kong-control-plane-kong-cluster.kong.svc.cluster.local
  # Issuer references are always required.
  issuerRef:
    name: intermediate2ca-issuer
    kind: Issuer
    group: cert-manager.io
EOF
```

You can check details of the certificate using a command like this;

```bash

kubectl get secret kong-control-plane-kong-cluster-inter -n kong -o jsonpath='{.data.tls\.crt}'|base64 -d|openssl x509 -text
```

#### Create the Data Plane certificate pair

Create the cert-manager configuration which creates the data plane certificate. Note, the Data plane needs the "Web Client Authentication" usage;

```bash

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kong-data-plane-kong-cluster-inter
  namespace: kong
spec:
  # Secret names are always required.
  secretName: kong-data-plane-kong-cluster-inter
  duration: 240h # 10d
  renewBefore: 48h # 2d
  commonName: kong-dp
  subject:
    organizations:
    - kong-dp
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  usages:
    - client auth
  # At least one of a DNS Name, URI, or IP address is required.
  dnsNames:
  - kong-data-plane-kong-cluster.kong.svc.cluster.local
  # Issuer references are always required.
  issuerRef:
    name: intermediate2ca-issuer
    kind: Issuer
    group: cert-manager.io
EOF
```

You can check details of the certificate using a command like this;

```bash

kubectl get secret kong-data-plane-kong-cluster-inter -n kong -o jsonpath='{.data.tls\.crt}'|base64 -d|openssl x509 -text
```

### Deploy the Kong Instance

When using intermediate certificates, it is important to set the `lua_ssl_verify_depth` parameter appropriately to ensure Kong can traverse the full certificate chain for verification. If this value is too small, you will see an error that the certificate chain is too long.

#### Deploy the Control Plane

Create a minimal control plane Helm chart named `minimal-kong-hybrid-control.yaml`

```yaml

# Basic configuration for Kong without the ingress controller, using the Postgres subchart
# This installation does not create an Ingress or LoadBalancer Service for
# the Admin API. It requires port-forwards to access without further
# configuration to add them, e.g.:
# kubectl port-forward deploy/your-deployment-kong 8001:8001

image:
  repository: kong/kong-gateway
  tag: "3.14.0.0"

enterprise:
  enabled: true

env:
  prefix: /kong_prefix/
  anonymous_reports: off

  database: postgres
  pg_username: kong
  pg_password: password
  pg_database: kong

  role: control_plane
  cluster_mtls: pki
  cluster_telemetry_listen: 0.0.0.0:8006
  cluster_ca_cert: /etc/secrets/cluster-fullchain/chain.pem
  cluster_cert: /etc/secrets/kong-control-plane-kong-cluster-inter/tls.crt
  cluster_cert_key: /etc/secrets/kong-control-plane-kong-cluster-inter/tls.key
  lua_ssl_verify_depth: 5

admin:
  enabled: true
  http:
    enabled: true
    servicePort: 8001
    containerPort: 8001

cluster:
  enabled: true
  tls:
    enabled: true
    servicePort: 8005
    containerPort: 8005

proxy:
  enabled: false

secretVolumes:
  - kong-control-plane-kong-cluster-inter
  - cluster-fullchain

postgresql:
  enabled: true
  # The Kong Helm chart's bundled postgresql subchart no longer ships a default image
  # (the plain "bitnami/postgresql" repository stopped publishing this tag). Use
  # "bitnamilegacy/postgresql", or any other Postgres image you host yourself.
  image:
    registry: docker.io
    repository: bitnamilegacy/postgresql
    tag: "13"
  postgresqlUsername: kong
  postgresqlPassword: password
  postgresqlDatabase: kong
  service:
    port: 5432

ingressController:
  enabled: false
```

The secrets containing the PKI certificates are mounted as `secretVolumes`. This allows the certificates to be referred to via path names in the configuration.

Deploy the Control Plane using Helm

```bash

helm install kong-control-plane kong/kong -f minimal-kong-hybrid-control.yaml -n kong
```

#### Deploy the Data Plane

Create a minimal data plane Helm chart named `minimal-kong-hybrid-data.yaml`

```yaml

# Basic configuration for Kong as a hybrid mode data plane node.
# It depends on the presence of a control plane release, as shown in
# https://github.com/Kong/charts/blob/main/charts/kong/example-values/minimal-kong-hybrid-control.yaml
#
# The "env.cluster_control_plane" value must be changed to your control plane
# instance's cluster Service hostname. Search "CHANGEME" to find it in this
# example.
#
# Hybrid mode requires a certificate. See https://github.com/Kong/charts/blob/main/charts/kong/README.md#certificates
# to create one.

image:
  repository: kong/kong-gateway
  tag: "3.14.0.0"

env:
  prefix: /kong_prefix/
  database: "off"
  log_level: debug

  role: data_plane
  cluster_mtls: pki
  cluster_control_plane: kong-control-plane-kong-cluster.kong.svc.cluster.local:8005
  cluster_ca_cert: /etc/secrets/cluster-fullchain/chain.pem
  cluster_cert: /etc/secrets/kong-data-plane-kong-cluster-inter/tls.crt
  cluster_cert_key: /etc/secrets/kong-data-plane-kong-cluster-inter/tls.key
  lua_ssl_trusted_certificate: /etc/secrets/cluster-fullchain/chain.pem
  lua_ssl_verify_depth: 5

admin:
  enabled: false

proxy:
  enabled: true

secretVolumes:
  - kong-data-plane-kong-cluster-inter
  - cluster-fullchain

ingressController:
  enabled: false
```

The secrets containing the PKI certificates are mounted as `secretVolumes`. This allows the certificates to be referred to via path names in the configuration.

Deploy the Data Plane using Helm

```bash

helm install kong-data-plane kong/kong -f minimal-kong-hybrid-data.yaml -n kong
```

You will now have a Control Plane and a Data Plane pod, using cert-manager created certificates for PKI hybrid mode.
