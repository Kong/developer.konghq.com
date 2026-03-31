---
title: Deploy Self Managed Control Plane on Kubernetes
description: "Learn how to install Mesh Control plane on an existing Kubernetes cluster, and deploy the {{site.mesh_product_name}} demo application."
content_type: how_to
permalink: /mesh/deploy-mesh-self-managed/
bread-crumbs: 
  - /mesh/
related_resources:
  - text: "{{site.mesh_product_name}}"
    url: /mesh/overview/

products:
  - mesh

tldr:
  q: How do I install {{site.mesh_product_name}} with a {{site.konnect_short_name}} self managed Control plane
  a: Install {{site.mesh_product_name}} on your environment and manage the Control plane yourself.

prereqs:
  inline:
    - title: "Create a Kubernetes {{site.mesh_product_name}} control plane"
      content: |
        The {{site.mesh_product_name}} Control plan and Dataplane deployments are managed as part of the {{site.mesh_product_name}} Helm charts.  You will need a Kubernetes cluster to use this quick start.
---


{:.info}
>To install the {{site.mesh_product_name}} components on Universal / VM / Bare metal, follow the instructions [here](/mesh/deploy-universal-self-managed).

## Install {{site.mesh_product_name}}

Install {{site.mesh_product_name}} control plane and Kubernetes CRDs with Helm:

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

{:.info}
>When using the {{site.konnect_short_name}} managed control plane, all changes to the Mesh must be applied using `kumactl`.  You can configure `kumactl` connectivity by clicking on **Actions** from the Mesh overview in [{{site.konnect_short_name}}](https://cloud.konghq.com/us/mesh-manager).


## Forward ports

Port-forward the service to the namespace on port `5000`:

```sh
kubectl port-forward svc/demo-app -n kuma-demo 5000:5000
```

## Validate

Navigate to [`127.0.0.1:5000`](http://127.0.0.1:5000) in your web browser and increment the counter.

Now that you have you workloads up and running, we can secure them with Mutual TLS.

## Introduce zero-trust security

By default, service-to-service traffic in the mesh is not encrypted. You can change this in {{site.mesh_product_name}} by enabling the [Mutual TLS](/mesh/policies/mutual-tls/) (mTLS) policy, which provisions a dynamic Certificate Authority (CA) on the `default` Mesh. This CA automatically issues TLS certificates to all dataplanes.

To enable mTLS using a built-in CA:

{:.warning}
>Do not enable mTLS in an environment with existing workloads until you define a `MeshTrafficPermission` policy. 
>Without it, service-to-service communication will be blocked.


```sh
cat <<EOF | kumactl apply -f -
type: Mesh
name: default
mtls:
  enabledBackend: ca-1
  backends:
    - name: ca-1
      type: builtin
EOF
```

After enabling mTLS, service communication will be denied by default. To restore connectivity, apply a fully permissive [MeshTrafficPermission](/mesh/policies/meshtrafficpermission/) policy:

```sh
cat <<EOF | kumactl apply -f -
type: MeshTrafficPermission
name: allow-all
mesh: default
spec:
  from:
    - targetRef:
        kind: Mesh
      default:
        action: Allow
EOF
```