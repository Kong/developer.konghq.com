---
title: Deploy Mesh on Kubernetes
description: "Learn how to install Mesh on an existing Kubernetes cluster, and deploy the {{site.mesh_product_name}} demo application."
content_type: how_to

related_resources:
  - text: "{{site.mesh_product_name}}"
    url: /mesh/overview/

products:
  - gateway
  - mesh

works_on:
  - on-prem

tldr:
  q: How do I install Mesh on Kubernetes
  a: Install {{site.mesh_product_name}} on your Kubernetes cluster using Helm, and deploy the {{site.mesh_product_name}} demo application.

prereqs:
  skip_product: true 
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      content: |
        This guide requires a running Kubernetes cluster. If you already have a Kubernetes cluster running, you can skip this step. 
        It can be a cluster running locally, like Docker, or in a public cloud like AWS EKS, GCP GKE, etc.

        For example, if you are using [minikube](https://minikube.sigs.k8s.io/docs/):
        ```sh
        minikube start -p mesh-zone
        ```

cleanup:
  inline:
    - title: Clean up Mesh
      include_content: cleanup/products/mesh
      icon_url: /assets/icons/gateway.svg
---

## 1. Install {{site.mesh_product_name}}

Install {{site.mesh_product_name}} control plane with Helm:

```sh
helm repo add kong-mesh https://kong.github.io/kong-mesh-charts
helm repo update
helm install --create-namespace --namespace kong-mesh-system kong-mesh kong-mesh/kong-mesh
```

## 2. Deploy the demo application

To start learning how {{site.mesh_product_name}} works, you can use our simple and secure a simple demo application that consists of two services:

* `demo-app`: A web application that lets you increment a numeric counter. It listens on port `5000`
* `redis`: The data store for the counter

Deploy the demo application: 

```sh
kubectl apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml
kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
```

## 3. Forward Ports

Port-forward the service to the namespace on port `5000`:

```sh
kubectl port-forward svc/demo-app -n kuma-demo 5000:5000
```

## 4. Validate

The demo app consists of a web application called Kuma Counter. This application allows us to increment a counter. You can validate the installation was successful by visiting `http://127.0.0.1:5000/` and using the web application. When you click **Increment**, you will see the connection being managed from the terminal.