---
title: Deploy Kong Mesh on Kubernetes
description: Start learning how {{site.mesh_product_name}} works by running and securing a simple demo application that consists of two services.
content_type: how_to
permalink: /mesh/kubernetes/
products:
  - mesh
breadcrumbs:
  - /mesh/
works_on:
  - on-prem
tags:
  - get-started
  - kubernetes
  - quickstart
related_resources:
  - text: Get started with Red Hat OpenShift
    url: /mesh/openshift-quickstart/
  - text: Deploy Kong Mesh on Universal
    url: /mesh/get-started/universal/install/
  - text: '{{site.mesh_product_name}} data plane on Kubernetes'
    url: /mesh/data-plane-kubernetes/
tldr:
  q: How do I deploy {{site.mesh_product_name}} on Kubernetes?
  a: By the end of this guide, you will run {{site.mesh_product_name}} and secure traffic between demo services on Kubernetes.
prereqs:
  inline:
    - title: Helm
      include_content: prereqs/helm
    - title: A running Kubernetes cluster
      include_content: prereqs/kubernetes/mesh-cluster
---

To start learning how {{site.mesh_product_name}} works, you run and secure a simple demo application that consists of two services:

- `demo-app`: a web application that lets you increment a numeric counter. It listens on port 5000
- `redis`: data store for the counter


{% mermaid %}
---
title: service graph of the demo app
---
flowchart LR
demo-app(demo-app :5000)
redis(redis :6379)
demo-app --> redis
{% endmermaid %}


## Start a Kubernetes cluster

Start a new Kubernetes cluster on your local machine by executing the command below. The `-p` option creates a new profile named `mesh-zone`.

```sh
minikube start -p mesh-zone
```

{:.info}
> You can skip this step if you already have a Kubernetes cluster running. It can be a cluster running locally or in a public cloud like AWS EKS or GCP GKE.

## Install {{site.mesh_product_name}}

Install {{site.mesh_product_name}} control plane with Helm by executing:

```sh
helm repo add {{site.mesh_helm_repo_name}} {{site.mesh_helm_repo_url}}
helm repo update
helm install --create-namespace --namespace {{site.mesh_namespace}} {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }}
```

## Deploy the demo application

1. Deploy the application:
   ```sh
   kubectl apply -f https://raw.githubusercontent.com/kumahq/kuma-counter-demo/master/demo.yaml
   kubectl wait -n kuma-demo --for=condition=ready pod --selector=app=demo-app --timeout=90s
   ```

2. Port-forward the service to the namespace on port 5000:

   ```sh
   kubectl port-forward svc/demo-app -n kuma-demo 5000:5000
   ```

3. In a browser, go to [127.0.0.1:5000](http://127.0.0.1:5000) and increment the counter.

The demo app includes the `kuma.io/sidecar-injection` label enabled on the `kuma-demo` namespace.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kuma-demo
  labels:
    kuma.io/sidecar-injection: enabled
```

This means that {{site.mesh_product_name}} [already knows](/mesh/data-plane-kubernetes/) that it needs to automatically inject a sidecar proxy to every Kubernetes pod in the `kuma-demo` namespace.

## Explore the GUI

You can view the sidecar proxies that are connected to the {{site.mesh_product_name}} control plane.

{{site.mesh_product_name}} ships with a **read-only** [GUI](/mesh/interact-with-control-plane/) that you can use to retrieve {{site.mesh_product_name}} resources. By default, the GUI listens on the API port which defaults to `5681`.

To access {{site.mesh_product_name}}, first port-forward the API service:

```sh
kubectl port-forward svc/{{site.mesh_cp_name}} -n {{site.mesh_namespace}} 5681:5681
```

Then navigate to [127.0.0.1:5681/gui](http://127.0.0.1:5681/gui) to see the GUI.

To learn more, read the [documentation about the user interface](/mesh/interact-with-control-plane/).

## Introduce zero-trust security

By default, the network is **insecure and not encrypted**. You can change this with {{site.mesh_product_name}} by enabling
the [Mutual TLS](/mesh/policies/mutual-tls/) policy to provision a Certificate Authority (CA) that
will automatically assign TLS certificates to your services (more specifically to the injected data plane proxies running
alongside the services).

You can enable Mutual TLS with a `builtin` CA backend by executing:

{% if_version lte:2.8.x %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin" | kubectl apply -f -
```
{% endif_version %}
{% if_version gte:2.9.x %}
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
{% endif_version %}

The traffic is now **encrypted and secure**. {{site.mesh_product_name}} does not define default traffic permissions, which
means that no traffic will flow with mTLS enabled until you define a proper [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/)
[policy](/mesh/architecture/#policies).

For now, the demo application will not work.
You can verify this by clicking the increment button again and seeing the error message in the browser.
You can allow the traffic from the `demo-app` to `redis` by applying the following `MeshTrafficPermission`:

{% if_version lte:2.8.x %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: {{site.mesh_namespace}}
  name: redis
spec:
  targetRef:
    kind: MeshSubset
    tags:
      kuma.io/service: redis_kuma-demo_svc_6379
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: demo-app_kuma-demo_svc_5000
      default:
        action: Allow" | kubectl apply -f -
```
{% endif_version %}

{% if_version eq:2.9.x %}
```sh
echo "apiVersion: kuma.io/v1alpha1
kind: MeshTrafficPermission
metadata:
  namespace: kuma-demo
  name: redis
spec:
  targetRef:
    kind: MeshSubset
    tags:
      app: redis
  from:
    - targetRef:
        kind: MeshSubset
        tags:
          kuma.io/service: demo-app_kuma-demo_svc_5000
      default:
        action: Allow" | kubectl apply -f -
```
{% endif_version %}

{% if_version gte:2.10.x %}
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
{% endif_version %}

You can click the increment button again and the application should function once more.

## Next steps

- Explore the [Features](/mesh/enterprise/) available to govern and orchestrate your service traffic.
- Add a gateway to access the demo from the outside by following the [built-in gateway guide](/mesh/built-in-gateway/).
- Add Kong as a gateway to access the demo from the outside by following the [delegated gateway guide](/mesh/delegated-gateways/).
- [Federate](/mesh/federate/) a zone into a multi-zone deployment.
- Learn more about what you can do with the [GUI](/mesh/interact-with-control-plane/).
- Explore further installation strategies for [single-zone](/mesh/deploy-mesh-self-managed/) and [multi-zone](/mesh/federate/) environments.
- Read the [full documentation](/mesh/) to learn about all the capabilities of {{site.mesh_product_name}}.

## Validate

In your browser at [127.0.0.1:5000](http://127.0.0.1:5000), click **Increment** and confirm the counter updates successfully.
