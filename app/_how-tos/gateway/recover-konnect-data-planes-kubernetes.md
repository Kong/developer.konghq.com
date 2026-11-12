---
title: Reconnect {{site.konnect_short_name}} data planes after a Kubernetes cluster loss
short_title: Reconnect {{site.konnect_short_name}} data planes
description: "Save the Helm release and client certificate of a {{site.base_gateway}} data plane connected to Konnect, then reconnect a replacement data plane to the same control plane after the cluster is lost."
content_type: how_to

permalink: /how-to/reconnect-konnect-data-planes-after-cluster-loss/
breadcrumbs:
  - /gateway/
  - /gateway/disaster-recovery/kubernetes/

products:
  - gateway

works_on:
  - konnect

entities: []

tags:
  - kubernetes
  - restore
  - failover

tldr:
  q: How do I reconnect {{site.konnect_short_name}} data planes after I lose their Kubernetes cluster?
  a: |
    Before the failure, save the data plane's Helm values, the chart archive, and the client certificate and key that are registered with the control plane.
    In the replacement cluster, restore the certificate Secret and install the saved chart with the saved values.
    The new data plane connects to the same control plane and receives its current configuration.

prereqs:
  skip_product: true
  inline:
    - title: Create a k3d cluster
      position: before
      icon_url: /assets/icons/kubernetes.svg
      include_content: prereqs/kubernetes/k3d-dr-cluster
    - title: "{{site.konnect_short_name}} personal access token"
      icon_url: /assets/icons/gateway.svg
      content: |
        Create a [personal access token](https://cloud.konghq.com/global/account/tokens) in {{site.konnect_short_name}}, then export it:

        ```bash
        export KONNECT_TOKEN='YOUR KONNECT TOKEN'
        ```

    - title: jq
      icon_url: /assets/icons/code.svg
      content: |
        This guide uses [jq](https://jqlang.org/) to read values from API responses.
        Install it with your package manager, for example on macOS:

        ```bash
        brew install jq
        ```
    - title: "{{site.base_gateway}} data plane connected to {{site.konnect_short_name}}"
      icon_url: /assets/icons/gateway.svg
      include_content: prereqs/kubernetes/konnect-dr-data-plane

related_resources:
  - text: Recover {{site.konnect_short_name}}-managed data planes on Kubernetes
    url: /gateway/disaster-recovery/kubernetes/konnect/
  - text: Recover {{site.operator_product_name}} ownership of {{site.konnect_short_name}} entities after a cluster loss
    url: /operator/konnect/how-to/recover-entity-ownership-after-cluster-loss/
  - text: Prepare for disaster recovery on Kubernetes
    url: /gateway/disaster-recovery/kubernetes/prepare/

cleanup:
  inline:
    - title: Delete the control plane
      icon_url: /assets/icons/gateway.svg
      content: |
        ```bash
        curl -X DELETE "https://us.api.konghq.com/v2/control-planes/$CONTROL_PLANE_ID" \
          -H "Authorization: Bearer $KONNECT_TOKEN"
        ```
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

When you lose the Kubernetes cluster that runs your data planes, the {{site.konnect_short_name}} control plane and its configuration survive.
To recover traffic, you install replacement data planes that connect to the same control plane.
They receive the current configuration of the control plane, so you don't restore any Gateway configuration.

In this guide, you'll save a recovery set for the data plane that you created in the prerequisites, delete the cluster, and reconnect a data plane from a new cluster.
For what to save and how to adapt the procedure to your deployment, see [Recover {{site.konnect_short_name}}-managed data planes on Kubernetes](/gateway/disaster-recovery/kubernetes/konnect/).

## Record the baseline response

1. Read the address of the data plane proxy:

   ```bash
   export PROXY_IP=$(kubectl get svc --namespace kong kong-kong-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
   ```

1. Send a request through the data plane to record the baseline response:

   ```bash
   curl -i "http://$PROXY_IP/dr-check/anything"
   ```

   You'll see an `HTTP/1.1 200 OK` response from httpbin.
   If you see `404`, wait a few seconds for the data plane to receive the new configuration, and try again.

## Save the recovery set

In production, the recovery set lives in your deployment repository and secret store.
In this guide, a local `recovery` directory plays that role.

1. Create the directory:

   ```bash
   mkdir -p recovery
   ```

{% include k8s/disaster-recovery/save-helm-release.md release="kong" namespace="kong" chart="kong/kong" values_file="values-dp.yaml" version_var="GATEWAY_CHART_VERSION" %}

1. Save the client certificate and key.
   They must be the pair that's registered with the control plane:

   ```bash
   cp tls.crt tls.key recovery/
   ```

You don't need to save the control plane configuration.
It stays in {{site.konnect_short_name}}.

## Simulate the cluster loss

Delete the cluster.
The data plane pods, the Helm release, and the certificate Secret are deleted with it:

```bash
k3d cluster delete kong-dr
```

In {{site.konnect_short_name}}, the old data plane node stops reporting to the control plane.

## Create the replacement cluster

Create a new, empty cluster with the same name:

{% include k8s/disaster-recovery/k3d-cluster.md %}

## Reconnect the replacement data plane

1. Make sure that the control plane still exists:

   {% capture get_control_plane %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/control-planes/$CONTROL_PLANE_ID
   status_code: 200
   method: GET
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ get_control_plane | indent }}

1. Create the `kong` namespace:

   ```bash
   kubectl create namespace kong
   ```

1. Restore the client certificate Secret:

   ```bash
   kubectl create secret tls kong-cluster-cert -n kong \
     --cert=recovery/tls.crt --key=recovery/tls.key
   ```

1. Install the saved chart with the saved values:

   ```bash
   helm install kong "recovery/kong-${GATEWAY_CHART_VERSION}.tgz" -n kong \
     -f recovery/values-dp.yaml --wait --timeout 5m
   ```

## Validate

1. List the data plane nodes of the control plane:

   {% capture list_nodes %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/control-planes/$CONTROL_PLANE_ID/nodes
   status_code: 200
   method: GET
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ list_nodes | indent }}

   You'll see a node whose `hostname` matches the new data plane pod.

1. The replacement data plane has a new load balancer address.
   Read it:

   ```bash
   export PROXY_IP=$(kubectl get svc --namespace kong kong-kong-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')
   ```

1. Send the baseline request again:

   ```bash
   curl -i "http://$PROXY_IP/dr-check/anything"
   ```

   You'll see the same `HTTP/1.1 200 OK` response from httpbin.

1. To make sure that the data plane receives new configuration, send a request to a path that the `dr-check` Route doesn't match yet.
   Route paths are prefixes, so `/dr-check-recovered` would already match:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" "http://$PROXY_IP/dr-verify/anything"
   ```

   You'll see `404`.

1. Add the `/dr-verify` path to the Route.
   The `PUT` request replaces the whole Route, so it includes every field:

   {% capture update_route %}
   <!--vale off-->
   {% konnect_api_request %}
   url: /v2/control-planes/$CONTROL_PLANE_ID/core-entities/routes/$ROUTE_ID
   status_code: 200
   method: PUT
   body:
     name: dr-check
     paths:
       - /dr-check
       - /dr-verify
     protocols:
       - http
     service:
       id: $SERVICE_ID
   {% endkonnect_api_request %}
   <!--vale on-->
   {% endcapture %}
   {{ update_route | indent }}

1. Wait a few seconds, then send the request again:

   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" "http://$PROXY_IP/dr-verify/anything"
   ```

   You'll see `200`.
