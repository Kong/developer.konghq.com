---
title: Recover a {{site.kic_product_name_short}} deployment after a cluster loss
short_title: Recover from a cluster loss
description: "Save the Helm release, routing resources, and TLS certificate of a DB-less {{site.kic_product_name}} deployment, then restore them in a replacement Kubernetes cluster."
content_type: how_to

permalink: /kubernetes-ingress-controller/recover-from-cluster-loss/
breadcrumbs:
  - /kubernetes-ingress-controller/

products:
  - kic

works_on:
  - on-prem

entities: []

tags:
  - kubernetes
  - backup
  - restore
  - failover

tldr:
  q: How do I recover a {{site.kic_product_name_short}} deployment after I lose its Kubernetes cluster?
  a: |
    Before the failure, save the Helm values, the chart archive, the routing manifests, and their Secrets outside the cluster.
    In the replacement cluster, restore the Secrets, install the saved chart with the saved values, wait for the controller, then apply the routing manifests.

prereqs:
  enterprise: true
  inline:
    - title: Create a k3d cluster
      position: before
      icon_url: /assets/icons/kubernetes.svg
      include_content: prereqs/kubernetes/k3d-dr-cluster
    - title: Create the routing configuration
      icon_url: /assets/icons/kubernetes.svg
      include_content: prereqs/kubernetes/kic-dr-routing

related_resources:
  - text: Disaster recovery for DB-less deployments managed by {{site.kic_product_name_short}}
    url: /kubernetes-ingress-controller/disaster-recovery/
  - text: Prepare for disaster recovery on Kubernetes
    url: /gateway/disaster-recovery/kubernetes/prepare/
  - text: Test disaster recovery on Kubernetes
    url: /gateway/disaster-recovery/kubernetes/test/

cleanup:
  inline:
    - title: Delete the k3d cluster and the recovery files
      icon_url: /assets/icons/kubernetes.svg
      content: |
        ```bash
        k3d cluster delete kong-dr
        ```

        ```bash
        rm -rf recovery
        ```

automated_tests: false
---

A DB-less {{site.base_gateway}} managed by {{site.kic_product_name}} gets all of its configuration from Kubernetes resources.
When you lose the cluster, you rebuild the deployment from a recovery set: files and Secrets that you saved outside the cluster.

In this guide, you'll save a recovery set for the routing configuration that you created in the prerequisites, delete the cluster, and restore the deployment in a new cluster.
For the full list of what to save and how to adapt the procedure to your deployment, see [Disaster recovery for DB-less deployments managed by {{site.kic_product_name_short}}](/kubernetes-ingress-controller/disaster-recovery/).

## Record the baseline response

Send a request through the proxy:

```bash
curl --fail-with-body --cacert recovery/tls.crt \
  --resolve "echo.example.com:443:$PROXY_IP" \
  https://echo.example.com/echo
```

You'll see a response from the echo application that names the pod that served it.

## Save the recovery set

The `recovery` directory already holds the routing manifest and the certificate that you created in the prerequisites.
Add the Helm release and the license.

{% include k8s/disaster-recovery/save-helm-release.md release="kong" namespace="kong" chart="kong/ingress" values_file="values.yaml" version_var="KIC_CHART_VERSION" %}

1. Save the {{site.ee_product_name}} license:

   ```bash
   cp license.json recovery/license.json
   ```

## Simulate the cluster loss

Delete the cluster.
The Helm release, the Secrets, and the routing resources are deleted with it:

```bash
k3d cluster delete kong-dr
```

## Create the replacement cluster

Create a new, empty cluster with the same name:

{% include k8s/disaster-recovery/k3d-cluster.md %}

## Restore the Secrets

The chart values and the Ingress reference Secrets, so restore them before you install the chart.

1. Create the `kong` namespace:

   ```bash
   kubectl create namespace kong
   ```

1. Restore the license Secret:

   ```bash
   kubectl create secret generic kong-enterprise-license -n kong \
     --from-file=license=recovery/license.json
   ```

1. Restore the TLS Secret:

   ```bash
   kubectl create secret tls echo-tls -n kong \
     --cert=recovery/tls.crt --key=recovery/tls.key
   ```

## Restore the Helm release

1. Install the saved chart with the saved values.
   Keep the release name and namespace, so that the Service names that the chart generates stay the same:

   ```bash
   helm install kong "recovery/ingress-${KIC_CHART_VERSION}.tgz" -n kong \
     -f recovery/values.yaml
   ```

1. Wait for the controller:

   ```bash
   kubectl rollout status deployment/kong-controller -n kong --timeout=300s
   ```

Don't wait for the gateway to become ready.
A DB-less gateway can need its routing configuration to pass its readiness check, and you restore that configuration in the next step.

## Restore the application and routes

1. Apply the saved manifest:

   ```bash
   kubectl apply -n kong -f recovery/resources.yaml
   ```

1. Wait for the echo application:

   ```bash
   kubectl rollout status deployment/echo -n kong --timeout=300s
   ```

## Validate

1. The replacement cluster has a new load balancer address.
   Read it:

   ```bash
   export PROXY_IP=$(kubectl get svc --namespace kong kong-gateway-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
   ```

1. Send the baseline request again:

   ```bash
   curl --fail-with-body --cacert recovery/tls.crt \
     --resolve "echo.example.com:443:$PROXY_IP" \
     https://echo.example.com/echo
   ```

   You'll see a response from a pod in the replacement cluster.
   The restored certificate is valid, because `curl` trusts only `recovery/tls.crt`.

1. To make sure that the controller still processes new configuration, send a request to a path that no Ingress matches yet:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" --cacert recovery/tls.crt \
     --resolve "echo.example.com:443:$PROXY_IP" \
     https://echo.example.com/echo-recovered
   ```

   You'll see `404`.

1. Create an Ingress for that path:

   ```bash
   echo '
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: echo-recovered
     namespace: kong
   spec:
     ingressClassName: kong
     tls:
       - hosts:
           - echo.example.com
         secretName: echo-tls
     rules:
       - host: echo.example.com
         http:
           paths:
             - path: /echo-recovered
               pathType: Prefix
               backend:
                 service:
                   name: echo
                   port:
                     number: 1027
   ' | kubectl apply -f -
   ```

1. Send the request again:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" --cacert recovery/tls.crt \
     --resolve "echo.example.com:443:$PROXY_IP" \
     https://echo.example.com/echo-recovered
   ```

   You'll see `200`.
