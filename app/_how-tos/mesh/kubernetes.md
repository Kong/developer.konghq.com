---
title: Deploy {{site.mesh_product_name}} on Kubernetes
description: Start learning how {{site.mesh_product_name}} works by running and securing a simple demo application that consists of two services.
content_type: how_to
permalink: /mesh/kubernetes/
products:
  - mesh
breadcrumbs:
  - /mesh/
works_on:
  - on-prem
min_version:
  mesh: "2.10"
tags:
  - get-started
  - kubernetes
  - quickstart
related_resources:
  - text: Get started with Red Hat OpenShift
    url: /mesh/openshift-quickstart/
  - text: Deploy {{site.mesh_product_name}} on Universal
    url: /mesh/get-started/universal/install/
  - text: '{{site.mesh_product_name}} data plane on Kubernetes'
    url: /mesh/data-plane-kubernetes/
tldr:
  q: How do I deploy {{site.mesh_product_name}} on Kubernetes?
  a: Install the {{site.mesh_product_name}} control plane with Helm, deploy a demo application, enable mTLS to encrypt service-to-service traffic, and apply a `MeshTrafficPermission` policy to allow traffic between the demo services.
prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
---

To start learning how {{site.mesh_product_name}} works, run and secure a simple demo application that consists of two services:

* `demo-app`: a web application that lets you increment a numeric counter and listens on port 5000.
* `redis`: data store for the counter.


{% mermaid %}
flowchart LR
demo-app(demo-app :5000)
redis(redis :6379)
demo-app --> redis
{% endmermaid %}


## Install {{site.mesh_product_name}}

Install the {{site.mesh_product_name}} control plane with Helm:

```sh
helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}}
helm repo update
helm install --create-namespace --namespace {{site.mesh_namespace}} {{site.mesh_helm_install_name}} {{site.mesh_helm_repo}}
```

## Deploy the demo application

1. Deploy the demo application:

   ```sh
   kubectl apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml
   ```

1. Wait for the `demo-app` pod to be ready:

   ```sh
   kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
   ```

1. Port-forward the service to the namespace on port 5000:

   ```sh
   kubectl port-forward svc/demo-app -n kuma-demo 5000:5000
   ```

1. In a browser, go to <http://127.0.0.1:5000> and increment the counter.

## Explore the user interface

{{site.mesh_product_name}} ships with a read-only [UI](/mesh/interact-with-control-plane/) that you can use to view the sidecar proxies connected to the control plane and retrieve {{site.mesh_product_name}} resources. By default, the UI listens on the API port `5681`.

1. In a new terminal, port-forward the API service:

   ```sh
   kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
   ```

1. In a browser, go to <http://127.0.0.1:5681/gui>.

For more details, see [Interacting with the {{site.mesh_product_name}} control plane](/mesh/interact-with-control-plane/).

## Introduce zero-trust security

By default, traffic between services is insecure and not encrypted. To encrypt traffic, enable the [Mutual TLS](/mesh/policies/mutual-tls/) policy. The policy provisions a Certificate Authority (CA) that automatically assigns TLS certificates to the injected data plane proxies running alongside the services.

In a new terminal, run the following command to enable Mutual TLS with a `builtin` CA backend:

```sh
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  meshServices:
    mode: Exclusive
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin" | kubectl apply -f -
```

Traffic is now encrypted and secure. 

## Allow traffic from `demo-app` to `redis`

{{site.mesh_product_name}} doesn't define default traffic permissions, so no traffic flows with mTLS enabled until you define a [`MeshTrafficPermission`](/mesh/policies/meshtrafficpermission/) policy.

The demo app no longer works, if you click the increment button again you should get an error message in your browser.

To allow traffic from `demo-app` to `redis`, apply a `MeshTrafficPermission`:

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

1. In a browser, go to <http://127.0.0.1:5000>.
1. Click **Increment**.
   
   The counter value should increase.
