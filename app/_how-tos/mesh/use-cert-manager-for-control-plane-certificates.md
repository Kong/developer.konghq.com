---
title: Use cert-manager for control plane certificates
description: Learn how to use cert-manager to provision and rotate TLS certificates for the {{site.mesh_product_name}} control plane on Kubernetes.
content_type: how_to
permalink: /mesh/use-cert-manager-for-control-plane-certificates/
products:
  - mesh
works_on:
  - on-prem
breadcrumbs:
  - /mesh/
tags:
  - cert-manager
  - certificates
  - security
tldr:
  q: How do I use cert-manager to manage control plane TLS certificates?
  a: Create a self-signed `ClusterIssuer`, a CA `Certificate`, a CA-backed `Issuer`, and a control plane `Certificate` in the `kong-mesh-system` namespace, then set `controlPlane.tls.general.secretName` in your Helm values to point to the generated secret.
prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
    - title: Install cert-manager
      include_content: prereqs/cert-manager
cleanup:
  inline:
    - title: Clean up {{site.mesh_product_name}}
      include_content: cleanup/products/mesh
related_resources:
  - text: Deploy Mesh on Kubernetes
    url: /mesh/deploy-mesh-on-kubernetes/
  - text: Deploy Mesh (self-managed)
    url: /mesh/deploy-mesh-self-managed/
---

By default, {{site.mesh_product_name}} generates its own self-signed control plane certificates at startup. Using cert-manager lets you manage the full certificate lifecycle — issuance, rotation, and expiration — outside of the control plane itself. This guide walks you through creating the required cert-manager resources and configuring {{site.mesh_product_name}} to use them.

## Create the {{site.mesh_product_name}} namespace

The cert-manager resources in the following steps are scoped to the `kong-mesh-system` namespace, which {{site.mesh_product_name}} uses at install time. Create it now so the namespace exists before you apply any certificates:

```sh
kubectl create namespace kong-mesh-system
```

## Create a self-signed ClusterIssuer

A `ClusterIssuer` is a cluster-scoped resource that cert-manager uses to sign certificates. Create a self-signed one as the root of your certificate chain:

```sh
echo "apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}" | kubectl apply -f -
```

## Create the CA certificate

Use the `selfsigned-issuer` to create a CA certificate in the `kong-mesh-system` namespace. This certificate acts as the root CA that signs the control plane certificate:

```sh
echo "apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kong-mesh-selfsigned-ca
  namespace: kong-mesh-system
spec:
  isCA: true
  commonName: kong-mesh-selfsigned-ca
  secretName: root-secret
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io" | kubectl apply -f -
```

cert-manager stores the CA certificate and key in a secret named `root-secret` in the `kong-mesh-system` namespace.

## Create the CA-backed Issuer

Create a namespace-scoped `Issuer` in `kong-mesh-system` that uses the CA secret to sign certificates:

```sh
echo "apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: kong-mesh-issuer
  namespace: kong-mesh-system
spec:
  ca:
    secretName: root-secret" | kubectl apply -f -
```

## Create the control plane certificate

Create a `Certificate` resource that cert-manager uses to issue and renew the control plane TLS certificate. The `dnsNames` must include all the DNS names that data planes use to reach the control plane:

```sh
echo "apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: control-plane-cert
  namespace: kong-mesh-system
spec:
  secretName: control-plane-cert
  duration: 2160h # 90d
  renewBefore: 360h # 15d
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  usages:
    - server auth
  dnsNames:
    - kong-mesh-control-plane.kong-mesh-system.svc
    - kong-mesh-control-plane
    - kong-mesh-control-plane.kong-mesh-system
    - kong-mesh-control-plane.kong-mesh-system.svc.local
  issuerRef:
    name: kong-mesh-issuer
    kind: Issuer" | kubectl apply -f -
```

Wait for the certificate to be issued:

```sh
kubectl wait -n kong-mesh-system --for=condition=ready certificate/control-plane-cert --timeout=60s
```

## Install {{site.mesh_product_name}} with the cert-manager certificate

Install {{site.mesh_product_name}} and point the control plane TLS configuration at the secret cert-manager created:

```sh
helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
helm repo update
helm upgrade --install \
  --namespace kong-mesh-system \
  kong-mesh kong-mesh/kong-mesh \
  --set controlPlane.tls.general.secretName=control-plane-cert
kubectl wait -n kong-mesh-system --for=condition=ready pod --selector=app=kong-mesh-control-plane --timeout=90s
```

If {{site.mesh_product_name}} is already installed, run `helm upgrade` instead of `helm install` with the same `--set` flag.

## Validate

Verify that the control plane is running and using the cert-manager-issued certificate:

1. Confirm the control plane pod is healthy:

   ```sh
   kubectl get pods -n kong-mesh-system
   ```

   The `kong-mesh-control-plane` pod should show `Running` in the `STATUS` column.
   {:.no-copy-code}

1. Inspect the certificate that cert-manager stored in the secret:

   ```sh
   kubectl get secret -n kong-mesh-system control-plane-cert \
     -o jsonpath='{.data.tls\.crt}' | base64 -d | \
     openssl x509 -noout -subject -issuer -dates
   ```

   The output should show `kong-mesh-selfsigned-ca` as the issuer and an expiration date 90 days from issuance. For example: 

   ```text
   subject=
   issuer=CN=kong-mesh-selfsigned-ca
   notBefore=Jun 17 09:50:10 2026 GMT
   notAfter=Sep 15 09:50:10 2026 GMT
   ```
   {:.no-copy-code}

   {:.info}
   > The subject is empty because cert-manager sets identity via SANs rather than a common name.

1. Confirm cert-manager will renew the certificate automatically:

   ```sh
   kubectl get certificate -n kong-mesh-system control-plane-cert
   ```

   The `READY` column should show `True`.
