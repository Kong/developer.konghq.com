---
title: Recover a Gateway managed by {{site.operator_product_name}} after a cluster loss
short_title: Recover from a cluster loss
description: "Save the Kong Operator Helm release and the Gateway API resources that you wrote, then restore them in a replacement Kubernetes cluster so that the operator recreates the Gateway."
content_type: how_to

permalink: /operator/dataplanes/how-to/recover-from-cluster-loss/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment

products:
  - operator

works_on:
  - on-prem

min_version:
  operator: '2.1'

entities: []

tags:
  - kubernetes
  - backup
  - restore
  - failover

tldr:
  q: How do I recover a Gateway managed by {{site.operator_product_name}} after I lose its Kubernetes cluster?
  a: |
    Before the failure, save the operator's Helm values and chart archive, and the GatewayConfiguration, GatewayClass, Gateway, and route manifests that you wrote.
    In the replacement cluster, install the saved chart, then apply the saved manifests.
    The operator creates new data plane workloads from them.

prereqs:
  enterprise: true
  inline:
    - title: Create a k3d cluster
      position: before
      icon_url: /assets/icons/kubernetes.svg
      include_content: prereqs/kubernetes/k3d-dr-cluster
    - title: Create the Gateway and an HTTPRoute
      icon_url: /assets/icons/kubernetes.svg
      include_content: prereqs/operator/dr-gateway-resources

related_resources:
  - text: Disaster recovery for Gateways managed by {{site.operator_product_name}}
    url: /operator/dataplanes/disaster-recovery/
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

{{site.operator_product_name}} creates the data plane Deployments and Services of a Gateway from the Gateway API resources that you write.
To recover a Gateway after a cluster loss, you only need those resources and the operator's Helm release.
You don't save the Deployments and Services that the operator generates, because it recreates them.

In this guide, you'll save a recovery set for the Gateway that you created in the prerequisites, delete the cluster, and restore the Gateway in a new cluster.
For the full list of what to save and how to adapt the procedure to your deployment, see [Disaster recovery for Gateways managed by {{site.operator_product_name}}](/operator/dataplanes/disaster-recovery/).

## Record the baseline response

1. Read the address of the Gateway:

   ```bash
   export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
   ```

1. Send a request through the Gateway:

   ```bash
   curl --fail-with-body "http://$PROXY_IP/echo"
   ```

   You'll see a response from the echo application that names the pod that served it.

## Save the recovery set

The `recovery` directory already holds the Gateway resources that you created in the prerequisites.
Add the operator's Helm release and the license.

{% include k8s/disaster-recovery/save-helm-release.md release="kong-operator" namespace="kong-system" chart="kong/kong-operator" values_file="values.yaml" version_var="OPERATOR_CHART_VERSION" %}

1. Save the {{site.ee_product_name}} license:

   ```bash
   cp license.json recovery/license.json
   ```

## Simulate the cluster loss

Delete the cluster.
The operator, the Gateway, and the data plane workloads are deleted with it:

```bash
k3d cluster delete kong-dr
```

## Create the replacement cluster

Create a new, empty cluster with the same name:

{% include k8s/disaster-recovery/k3d-cluster.md %}

## Reinstall the operator

1. Install the saved chart with the saved values.
   The chart also installs the CRDs that the saved resources use, including the Gateway API CRDs:

   ```bash
   helm install kong-operator "recovery/kong-operator-${OPERATOR_CHART_VERSION}.tgz" \
     -n kong-system --create-namespace \
     -f recovery/values.yaml --wait --timeout 5m
   ```

1. Restore the license as a KongLicense resource:

   ```bash
   echo "
   apiVersion: configuration.konghq.com/v1alpha1
   kind: KongLicense
   metadata:
    name: kong-license
   rawLicenseString: '$(cat ./recovery/license.json)'
   " | kubectl apply -f -
   ```

## Restore the Gateway and routes

1. Apply the saved manifest.
   It lists the resources in dependency order, so each resource exists before the next one references it:

   ```bash
   kubectl apply -n kong -f recovery/resources.yaml
   ```

1. Wait for {{site.operator_product_name}} to program the Gateway:

   ```bash
   kubectl wait --for=condition=Programmed gateway/kong -n kong --timeout=300s
   ```

## Validate

1. The recovered Gateway has a new address.
   Read it:

   ```bash
   export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
   ```

1. Send the baseline request again:

   ```bash
   curl --fail-with-body "http://$PROXY_IP/echo"
   ```

   You'll see a response from a pod in the replacement cluster.

1. To make sure that the operator still processes new configuration, send a request to a path that no HTTPRoute matches yet:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" "http://$PROXY_IP/echo-recovered"
   ```

   You'll see `404`.

1. Create an HTTPRoute for that path:

   ```bash
   echo '
   kind: HTTPRoute
   apiVersion: gateway.networking.k8s.io/v1
   metadata:
     name: echo-recovered
     namespace: kong
   spec:
     parentRefs:
       - group: gateway.networking.k8s.io
         kind: Gateway
         name: kong
     rules:
       - matches:
           - path:
               type: PathPrefix
               value: /echo-recovered
         backendRefs:
           - name: echo
             port: 1027
   ' | kubectl apply -f -
   ```

1. Send the request again:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" "http://$PROXY_IP/echo-recovered"
   ```

   You'll see `200`.
