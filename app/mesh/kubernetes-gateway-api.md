---
title: "Kubernetes built-in gateways with {{site.mesh_product_name}}"
description: "Learn how to use Kubernetes Gateway API with {{site.mesh_product_name}}, including support for built-in gateways, HTTP/TCP routing, TLS, GAMMA, and multi-zone limitations."
content_type: reference
layout: reference
products:
    - mesh
breadcrumbs:
  - /mesh/

works_on:
  - on-prem
  - konnect

min_version:
  mesh: '2.9'

related_resources:
  - text: Deploy {{site.mesh_product_name}} on Kubernetes
    url: /mesh/kubernetes/
  - text: Data Plane on Kubernetes
    url: /mesh/data-plane-kubernetes/
  - text: "Built-in gateways"
    url: '/mesh/built-in-gateway/'
  - text: "Set up a built-in Kubernetes gateway with {{site.mesh_product_name}}"
    url: /how-to/set-up-a-built-in-kubernetes-gateway/
  - text: Multi-zone deployment
    url: '/mesh/mesh-multizone-service-deployment/'
---

{{site.mesh_product_name}} supports the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) for configuring [built-in gateways](/mesh/built-in-gateway/) as well as traffic routing using the experimental [GAMMA](https://gateway-api.sigs.k8s.io/contributing/gamma/) [routing spec](https://gateway-api.sigs.k8s.io/geps/gep-1426/).

To learn how to use the Kubernetes Gateway API to deploy a built-in gateway, see [Set up a built-in Kubernetes gateway with {{site.mesh_product_name}}](/how-to/set-up-a-built-in-kubernetes-gateway/). 

## Customization

The Gateway API provides the `parametersRef` field on `GatewayClass.spec` to add implementation-specific configuration to the `Gateway` resource.
When using the Kubernetes Gateway API with {{site.mesh_product_name}}, you can refer to a `MeshGatewayConfig` resource:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kuma
spec:
  controllerName: gateways.kuma.io/controller
  parametersRef:
    kind: MeshGatewayConfig
    group: kuma.io
    name: kuma
```

This resource has the same structure as the [`MeshGatewayInstance` resource](/mesh/gateway-pods-k8s/), but the `tags` field is optional.
With a `MeshGatewayConfig`, you can then customize the generated `Service` and `Deployment` resources.

## Multi-mesh

You can specify a `Mesh` for `Gateway` and `HTTPRoute` resources by setting the [`kuma.io/mesh` annotation](/mesh/annotations/#kuma-io-mesh)
{:.info}
> `HTTPRoutes` must also have the annotation to reference a `Gateway` from a non-default `Mesh`.

## Cross-mesh

[Cross-mesh gateways](/mesh/gateway-listeners/#cross-mesh) are supported with the Gateway API.
Create a corresponding `GatewayClass` pointing to a `MeshGatewayConfig` that sets `crossMesh: true`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kuma-cross-mesh
spec:
  controllerName: gateways.kuma.io/controller
  parametersRef:
    group: kuma.io
    kind: MeshGatewayConfig
    name: default-cross-mesh
---
apiVersion: kuma.io/v1alpha1
kind: MeshGatewayConfig
metadata:
  name: default-cross-mesh
spec:
  crossMesh: true
```

Then reference it in your `Gateway`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kuma
  namespace: default
spec:
  gatewayClassName: kuma-cross-mesh
  listeners:
  - name: proxy
    port: 8080
    protocol: HTTP
```

## Multi-zone deployments

{% capture backendref-limitation %}
{:.warning}
> This limitation exists because {{site.mesh_product_name}} currently only allows referencing as `backendRefs` [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/).
> 
> This is a temporary limitation. [We're actively working on extending `backendRef` to support {{site.mesh_product_name}}'s `MeshServices`](https://github.com/kumahq/kuma/issues/9894). Once this feature is complete, you'll be able to reference services across different clusters within your mesh.
{% endcapture %}

{% capture backendref-limitation-environment %}
{% mermaid %}
flowchart TD
    subgraph c2["k8s-cluster-2"]
        subgraph z2["zone-2"]
            subgraph c1z2s1["Service"]
                b2(backend)
            end
            subgraph c1z2s2["Service"]
                db(db)
            end
        end
    end
    subgraph c1["k8s-cluster-1"]
        subgraph z1["zone-1"]
            subgraph Gateway
                listener(:8080)
            end
            subgraph Service
                b1(backend)
            end
        end
    end
{% endmermaid %}
{% endcapture %}

{% capture gapi_multizone_limitation_1 %}
{% mermaid %}
flowchart TD
    subgraph c2["k8s-cluster-2"]
        subgraph z2["zone-2"]
            subgraph c1z2s1["Service"]
                backend2(backend)
            end
            subgraph c1z2s2["Service"]
                db(db)
            end
        end
    end
    subgraph c1["k8s-cluster-1"]
        subgraph z1["zone-1"]
            subgraph Service
                backend1(backend)
            end
            subgraph Gateway
                listener(:8080)
            end
            subgraph HTTPRoute
                route1(/)
            end
            route1--"❌"-->backend2
            linkStyle 0 stroke:red,color:red,stroke-dasharray: 5 5;
            route1-->backend1
            listener-->route1
        end
    end
{% endmermaid %}
{% endcapture %}

{% capture gapi_multizone_limitation_2 %}
{% mermaid %}
flowchart TD
    subgraph c2["k8s-cluster-2"]
        subgraph z2["zone-2"]
            subgraph c1z2s1["Service"]
                backend2(backend)
            end
            subgraph c1z2s2["Service"]
                db(db)
            end
        end
    end
    subgraph c1["k8s-cluster-1"]
        subgraph z1["zone-1"]
            subgraph Gateway
                listener(:8080)
            end
            subgraph HTTPRoute
                route1(/)
            end
            subgraph Service
                backend1(backend)
            end
            route1--"❌"-->db
            linkStyle 0 stroke:red,color:red,stroke-dasharray: 5 5;
            listener-->route1
        end
    end
{% endmermaid %}
{% endcapture %}

The Gateway API supports multi-zone deployments, but with some limitations:

- Gateway API resources like `Gateway`, `ReferenceGrant`, and `HTTPRoute` must be created in non-global zones.

- Only services deployed within the same Kubernetes cluster, such as the `HTTPRoute`, can be referenced via `backendRef`.

   {{ backendref-limitation | indent }}

   To better visualize this limitation, here's an example scenario that describes how you could configure multi-zone deployments with the Gateway API. In this example, you have the following resources:

   - Two zones (`zone-1` and `zone-2`) in separate Kubernetes clusters

   - A Gateway with a listener on port `8080` deployed in `zone-1`

   - Two services:

      - A service named `backend` deployed in each zone 

      - A service named `db` deployed only in `zone-2`

   {{ backendref-limitation-environment | indent }}

   If you deploy multi-zone with the Gateway API, the following will occur:

   - If you create an `HTTPRoute` with a `backendRef` targeting the `backend` service in `k8s-cluster-1`, it will only route traffic to the `backend` service in `k8s-cluster-1`.
     
     {{ gapi_multizone_limitation_1 | indent }}

   - Similarly, if you create an `HTTPRoute` with a `backendRef` pointing to the `db` service in `k8s-cluster-1`, it will result in a `HTTPRoute` with a `ResolvedRefs` status condition of `BackendNotFound` because service `db` is not present in `k8s-cluster-1`.

     {{ gapi_multizone_limitation_2 | indent }}

## Service to service routing

{{site.mesh_product_name}} also supports routing between services with `HTTPRoute` in conformance with [the GAMMA specifications](https://gateway-api.sigs.k8s.io/geps/gep-1426/).

GAMMA is a Gateway API project focused on mesh implementations of the Gateway API and extending the Gateway API resources to mesh use cases.

The key feature of `HTTPRoute` for mesh routing is specifying a Kubernetes `Service` as the `parentRef`, as opposed to a `Gateway`.
All requests to this `Service` are then filtered and routed as specified in the `HTTPRoute`.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: canary-demo-app
  namespace: kuma-demo
spec:
  parentRefs:
  - name: demo-app
    port: 5000
    kind: Service
  rules:
  - backendRefs:
    - name: demo-app-v1
      port: 5000
    - name: demo-app-v2
      port: 5000
```

The namespace of the `HTTPRoute` is key. If the route's namespace and the `parentRef`'s namespace are identical, {{site.mesh_product_name}} applies the route to _requests from all workloads_.
If the route's namespace differs from its `parentRef`'s namespace, the `HTTPRoute` applies only to requests _from workloads in the route's namespace_.

{:.info}
> Remember to tag your `Service` ports with `appProtocol: http` to use them in an `HTTPRoute`.

{:.warning}
> Because of [how {{site.mesh_product_name}} currently maps resources](#how-it-works), the combination of the `HTTPRoute` name and namespace and the parent `Service` name and namespace must be no more than 249 characters.

## How it works

{{site.mesh_product_name}} includes controllers that reconcile the Gateway API CRDs and convert them into the corresponding {{site.mesh_product_name}} CRDs.
This is why in the GUI, {{site.mesh_product_name}} `MeshGateways`/`MeshHTTPRoutes`/`MeshTCPRoutes` are visible and not Kubernetes Gateway API resources.

Kubernetes Gateway API resources serve as the source of truth for {{site.mesh_product_name}} gateways and routes.
Any edits to the corresponding {{site.mesh_product_name}} resources are overwritten.
