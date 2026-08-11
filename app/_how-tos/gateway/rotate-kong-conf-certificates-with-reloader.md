---
title: Restart {{site.base_gateway}} when a mounted certificate changes
short_title: Rotate kong.conf certificates
description: "Use Stakater Reloader to roll out {{site.base_gateway}} pods automatically when cert-manager updates a mounted TLS Secret."
content_type: how_to
permalink: /how-to/rotate-kong-conf-certificates-with-reloader/

products:
  - gateway

works_on:
  - on-prem

tags:
  - certificates
  - cert-manager
  - kubernetes
  - helm
  - tls

tldr:
  q: How do I restart {{site.base_gateway}} automatically when cert-manager rotates a certificate that I mounted from a Secret?
  a: |
    Certificates set through `kong.conf` parameters such as `ssl_cert` or `cluster_cert` are read once at startup, so a rotated file on disk is ignored.
    Install [Stakater Reloader](https://github.com/stakater/Reloader) and annotate your Deployment with `secret.reloader.stakater.com/reload`.Reloader triggers a rolling restart whenever the Secret changes.
    Certificates served from [Certificate](/gateway/entities/certificate/) entities don't need this.

prereqs:
  skip_product: true
  inline:
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/cluster
      icon_url: /assets/icons/kubernetes.svg
    - title: Helm
      include_content: prereqs/helm
    - title: Install cert-manager
      include_content: prereqs/cert-manager
    - title: A {{site.base_gateway}} data plane
      include_content: prereqs/kubernetes/gateway-dbless
      icon_url: /assets/icons/kubernetes.svg

cleanup:
  inline:
    - title: Uninstall Reloader
      icon_url: /assets/icons/kubernetes.svg
      content: |
        ```bash
        helm uninstall reloader -n reloader
        kubectl delete namespace kong reloader
        ```
    - title: Uninstall {{site.base_gateway}}
      icon_url: /assets/icons/kubernetes.svg
      content: |
        ```bash
        helm uninstall kong-dp -n kong
        kubectl delete namespace kong
        ```
    - title: Uninstall cert-manager
      icon_url: /assets/icons/kubernetes.svg
      content: |
        ```bash
        helm uninstall cert-manager -n cert-manager
        kubectl delete namespace cert-manager
        ```

related_resources:
  - text: Rotate TLS certificates without restarting {{site.base_gateway}}
    url: /kubernetes-ingress-controller/routing/rotate-tls-certificates/
  - text: Automate TLS certificate provisioning and rotation with cert-manager
    url: /operator/dataplanes/how-to/cert-manager/
  - text: Restart {{site.base_gateway}} on Kubernetes
    url: /how-to/restart-kong-gateway-kubernetes/
  - text: Using SSL certificates in {{site.base_gateway}}
    url: /gateway/ssl-certificates/

automated_tests: false
---

Some {{site.base_gateway}} certificates can only be configured through `kong.conf`. Those values are rendered into the NGINX configuration when a node boots, so if [cert-manager](https://cert-manager.io/) rotates the Secret you mounted, the file on disk changes but {{site.base_gateway}} keeps serving the old certificate. The node has to be replaced before it reads the new file.

[Stakater Reloader](https://github.com/stakater/Reloader) watches ConfigMaps and Secrets and performs a rolling restart of the workloads that consume them. In this guide, we'll mount a cert-manager Secret into a data plane, watch the rotation fail to take effect, then set up Reloader and confirm that the pods are replaced automatically.

This guide uses `ssl_cert`, the default certificate for the proxy listener, because it's the easiest to observe with `openssl`. The same mechanism applies to every parameter listed below.

{:.warning}
> Check whether you need this first. Reloader restarts pods, so use it only when a certificate has no entity equivalent: 
> * `admin_ssl_cert`
> * `admin_gui_ssl_cert`
> * `status_ssl_cert`
> * `client_ssl_cert`
> * `cluster_cert`
> *  `lua_ssl_trusted_certificate`.
>
> For proxy certificates, including the `ssl_cert` used in this guide, prefer [Certificate](/gateway/entities/certificate/) and [SNI](/gateway/entities/sni/) entities in production. They rotate with no restart at all.

## Create a cert-manager Issuer

The `Issuer` resource represents the certificate authority that signs your certificates. Create a self-signed issuer in the `kong` namespace:

```bash
echo '
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
  namespace: kong
spec:
  selfSigned: {}' | kubectl apply -f -
```

{:.info}
> A self-signed issuer keeps this guide self-contained. In production, use an ACME issuer such as Let's Encrypt, or a CA issuer. For all issuer types, see the [cert-manager configuration documentation](https://cert-manager.io/docs/configuration/).

## Issue a certificate

1. Create a `Certificate` for the `demo.example.com` hostname. cert-manager writes the key pair to a Secret named `demo-example-com` and renews it automatically:

   ```bash
   echo '
   apiVersion: cert-manager.io/v1
   kind: Certificate
   metadata:
     name: demo-example-com
     namespace: kong
   spec:
     secretName: demo-example-com
     duration: 24h
     renewBefore: 12h
     issuerRef:
       name: selfsigned-issuer
       kind: Issuer
     dnsNames:
       - demo.example.com' | kubectl apply -f -
   ```

1. Wait for the certificate to be issued:

   ```bash
   kubectl wait --for=condition=Ready certificate/demo-example-com -n kong --timeout=90s
   ```

## Mount the Secret into the data plane

1. Create a `values-cert.yaml` file that mounts the Secret and serves it from the proxy listener:

   ```bash
   cat <<EOF > values-cert.yaml
   # Mount the certificate cert-manager issued
   secretVolumes:
     - demo-example-com

   env:
     ssl_cert: /etc/secrets/demo-example-com/tls.crt
     ssl_cert_key: /etc/secrets/demo-example-com/tls.key
   EOF
   ```

   Keep this in a separate file and layer it on top of `values-dp.yaml` rather than editing `values-dp.yaml` in place. Helm merges multiple `--values` files from left to right, so the data plane keeps the settings it was installed with.

   {:.info}
   > Don't point `status_ssl_cert` at a mounted certificate in this setup. The chart's readiness and liveness probes target the status port over plain HTTP, so turning it into a TLS listener stops the pod from becoming ready.

1. Apply the change and wait for the rollout:

   ```bash
   helm upgrade kong-dp kong/kong -n kong --values ./values-dp.yaml --values ./values-cert.yaml --wait
   ```

1. Store the pod name and confirm that the certificate is mounted:

   ```bash
   export DP_POD=$(kubectl get pods -n kong -l app.kubernetes.io/instance=kong-dp --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
   kubectl exec -n kong $DP_POD -- ls /etc/secrets/demo-example-com
   ```

   You should see the two files from the Secret:

   ```
   tls.crt
   tls.key
   ```
   {:.no-copy-code}

## Verify that the rotation is broken

1. Open a port forward to the proxy's TLS listener and record the serial number of the certificate it serves:

   ```bash
   kubectl port-forward -n kong $DP_POD 8443:8443 > /dev/null &
   sleep 3
   echo "" | openssl s_client -connect localhost:8443 -servername demo.example.com 2>/dev/null | openssl x509 -noout -serial -dates
   ```

   The output looks like this:

   ```
   serial=5B2C9A1E7F04D8B3A6E1C0F29D3847BA
   notBefore=Aug  7 10:12:04 2026 GMT
   notAfter=Aug  8 10:12:04 2026 GMT
   ```
   {:.no-copy-code}

1. Force cert-manager to reissue the certificate by deleting the Secret. cert-manager detects that the `Certificate` no longer has a valid Secret and reissues it immediately:

   ```bash
   kubectl delete secret demo-example-com -n kong
   kubectl wait --for=condition=Ready certificate/demo-example-com -n kong --timeout=90s
   ```

1. Wait for the kubelet to sync the new Secret into the pod, then compare the file on disk with what the listener serves:

   ```bash
   sleep 90
   kubectl exec -n kong $DP_POD -- openssl x509 -in /etc/secrets/demo-example-com/tls.crt -noout -serial
   echo "" | openssl s_client -connect localhost:8443 -servername demo.example.com 2>/dev/null | openssl x509 -noout -serial
   ```

   The file on disk has the new serial number, but the listener still serves the old one. {{site.base_gateway}} read the file at startup and hasn't looked at it since.

1. Close the port forward:

   ```bash
   kill %1
   ```

## Install Reloader

Install Reloader into its own namespace and wait for it to be ready:

```bash
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
helm upgrade --install reloader stakater/reloader -n reloader --create-namespace \
  --set reloader.reloadOnCreate=true
kubectl wait -n reloader --for=condition=ready pod --all --timeout=90s
```

## Annotate the Deployment

Add the `secret.reloader.stakater.com/reload` annotation to the data plane Deployment, listing the Secrets it should watch.

1. Append the annotation to `values-cert.yaml`:

   ```bash
   cat <<EOF >> values-cert.yaml

   deploymentAnnotations:
     secret.reloader.stakater.com/reload: "demo-example-com"
   EOF
   ```

1. Apply the change:

   ```bash
   helm upgrade kong-dp kong/kong -n kong --values ./values-dp.yaml --values ./values-cert.yaml --wait
   ```

1. Confirm that the annotation reached the Deployment:

   ```bash
   kubectl get deployment kong-dp-kong -n kong -o jsonpath='{.metadata.annotations}'
   ```

   The output should include your annotation:

   ```
   {"secret.reloader.stakater.com/reload":"demo-example-com"}
   ```
   {:.no-copy-code}

## Validate the rotation

1. Record the current pod name and age:

   ```bash
   kubectl get pods -n kong -l app.kubernetes.io/instance=kong-dp
   ```

1. Force another renewal:

   ```bash
   kubectl delete secret demo-example-com -n kong
   kubectl wait --for=condition=Ready certificate/demo-example-com -n kong --timeout=90s
   ```

1. Watch the rollout. Reloader detects the change and updates the Deployment, which replaces the pods:

   ```bash
   kubectl rollout status deployment/kong-dp-kong -n kong --timeout=300s
   ```

1. Confirm that the pod was replaced:

   ```bash
   kubectl get pods -n kong -l app.kubernetes.io/instance=kong-dp
   ```

   The pod name and age have changed and the number of restarts is `0` because the pod is new.

1. Confirm that the new certificate is now being served:

   ```bash
   export DP_POD=$(kubectl get pods -n kong -l app.kubernetes.io/instance=kong-dp --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
   kubectl port-forward -n kong $DP_POD 8443:8443 > /dev/null &
   sleep 3
   echo "" | openssl s_client -connect localhost:8443 -servername demo.example.com 2>/dev/null | openssl x509 -noout -serial -dates
   kubectl exec -n kong $DP_POD -- openssl x509 -in /etc/secrets/demo-example-com/tls.crt -noout -serial
   kill %1
   ```

   The two serial numbers should now match. {{site.base_gateway}} is serving the rotated certificate.

{:.warning}
> Reloader restarts the whole Deployment, so every `kong.conf` value is re-read, not just the certificate. Roll out configuration changes deliberately, and keep at least two replicas so a rotation doesn't take your data plane offline. With a single replica, as in this guide, expect a gap in service while the pod is replaced.
