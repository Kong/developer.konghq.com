---
title: Weight traffic to specific backends
description: "Distribute traffic across multiple Kubernetes Services in a single HTTPRoute"
content_type: how_to

permalink: /kubernetes-ingress-controller/routing/weights/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Routing

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I route HTTP traffic with a custom weight per backend using {{ site.kic_product_name }}?
  a: Create an `HTTPRoute` resource, and specify a `weight` property under `spec.rules[*].backendRefs[*].weight` to route traffic to specific backends.

prereqs:
  kubernetes:
    gateway_api: true

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## Deploy demo Services

This how-to deploys multiple Services to your Kubernetes cluster to simulate a production environment.

Deploy the Services and create routing resources:

```bash
kubectl apply -f {{ site.links.web }}/manifests/kic/echo-services.yaml -n kong
```

## Create an HTTPRoute

To route HTTP traffic, create an `HTTPRoute` resource pointing at your Kubernetes `Service`:

```bash
echo 'apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
 name: echo
 namespace: kong
 annotations:
   konghq.com/strip-path: "true"
spec:
 parentRefs:
 - name: kong
 rules:
 - matches:
   - path:
       type: PathPrefix
       value: /echo
   backendRefs:
   - name: echo
     kind: Service
     port: 80
   - name: echo2
     kind: Service
     port: 80
' | kubectl apply -f -
```

## Test your deployment

Send multiple requests through this Route and tabulate the results to check an even distribution of requests across the Services:

```bash
curl -s "$PROXY_IP/echo/hostname?iteration="{1..200} -w "\n" | sort | uniq -c
```

The results should look like this:

```text
100 echo2-7cb798f47-gv6hs
100 echo-658c5ff5ff-tv275
```
{:.no-copy-code}

## Add Service weights

The `weight` field overrides the default distribution of requests across Services. Each Service instead receives `weight / sum(all Service weights)` percent of the requests. 

1. Add weights to the Services in the HTTPRoute's backend list:

    ```bash
    kubectl patch -n kong --type json httproute echo -p='[
        {
          "op":"add",
          "path":"/spec/rules/0/backendRefs/0/weight",
          "value":200
        },
        {
          "op":"add",
          "path":"/spec/rules/0/backendRefs/1/weight",
          "value":100
        }
    ]'
    ```

1. Send the same requests again. This time, roughly 1/3 of the requests go to `echo2` and 2/3 go to `echo`:

    ```bash
    curl -s "$PROXY_IP/echo/hostname?iteration="{1..200} -w "\n" | sort | uniq -c
    ```

    The results should look like this:

    ```text
    133 echo-658c5ff5ff-tv275
     67 echo2-7cb798f47-gv6hs
   ```