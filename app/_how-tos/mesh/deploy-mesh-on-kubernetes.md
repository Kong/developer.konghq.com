---
title: Deploy Mesh on Kubernetes
description: "Learn how to install Mesh on an existing Kubernetes cluster, and deploy the {{site.mesh_product_name}} demo application."
content_type: how_to
permalink: /mesh/deploy-mesh-on-kubernetes/
bread-crumbs: 
  - /mesh/
related_resources:
  - text: "{{site.mesh_product_name}}"
    url: /mesh/overview/

products:
  - mesh

works_on:
  - konnect
  - on-prem

tldr:
  q: How do I install Mesh on Kubernetes
  a: Install {{site.mesh_product_name}} on your Kubernetes cluster using Helm, and deploy the {{site.mesh_product_name}} demo application.

prereqs:
  inline:
    - title: Create a {{site.mesh_product_name}} Control Plane
      content: |
        This tutorial requires a {{site.konnect_short_name}} Plus account. If you don't have one, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

        After creating your {{site.konnect_short_name}} account, [create the Kong Mesh Control Plane](https://cloud.konghq.com/us/mesh-manager/create-control-plane) and your first Mesh zone. Follow the instructions in {{site.konnect_short_name}} to deploy Mesh on your Kubernetes cluster.
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster

cleanup:
  inline:
    - title: Clean up Mesh
      include_content: cleanup/products/mesh
      icon_url: /assets/icons/gateway.svg
---


## Install {{site.mesh_product_name}}

Install {{site.mesh_product_name}} Control Plane with Helm:

```sh
helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
helm repo update
helm install --create-namespace --namespace kong-mesh-system kong-mesh kong-mesh/kong-mesh
```

## Deploy the demo application

To start learning how {{site.mesh_product_name}} works, you can use our simple and secure demo application that consists of two services:

* `demo-app`: A web application that lets you increment a numeric counter. It listens on port `5000`
* `redis`: The data store for the counter

{% mermaid %}
flowchart LR
  demo-app(demo-app :5000)
  redis(redis :6379)
  demo-app --> redis
{% endmermaid %}

Deploy the demo application: 

```sh
kubectl apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml
kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
```

## Forward ports

Port-forward the service to the namespace on port `5000`:

```sh
kubectl port-forward svc/demo-app -n kuma-demo 5000:5000
```

## Introduce zero-trust security


The traffic is now **encrypted and secure**. {{site.mesh_product_name}} does not define default traffic permissions, which
means that no traffic will flow with mTLS enabled until we define a proper [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/)
[policy](/mesh/policies/meshtls/).

For now, the demo application won't work.
You can verify this by clicking the increment button again and seeing the error message in the browser.
We can allow the traffic from the `demo-app` to `redis` by applying the following `MeshTrafficPermission`:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kuma-demo
  name: redis
spec:
  targetRef:
    kind: Dataplane
    labels:
      app: redis
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: demo-app_kuma-demo_svc_5000
      default:
        action: Allow" | kubectl apply -f -
```
## Validate

The demo app consists of a web application called Kuma Counter. This application allows us to increment a counter. You can validate the installation was successful by visiting `http://127.0.0.1:5000/` and using the web application. When you click **Increment**, you will see the connection being managed from the terminal.