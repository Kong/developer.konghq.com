---
title: Create a control plane
description: Define a {{site.konnect_short_name}} Gateway control plane and bind it to your cluster using a `KonnectExtension`.
content_type: how_to
permalink: /operator/get-started/konnect-crds/controlplane/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: operator-get-started-konnect-crds
  position: 3 

tldr:
  q: How do I create a control plane?
  a: |
    Define a `KonnectGatewayControlPlane` to point to your {{site.konnect_short_name}} instance, and a `KonnectExtension` to bind your Data Plane or Gateway to it.

prereqs:
  show_works_on: true
  skip_product: true
  operator:
    konnect:
      auth: true

products:
  - operator

works_on:
  - konnect

related_resources:
  - text: Deploy a data plane
    url: /operator/konnect/crd/dataplane/hybrid/

---

## Create a `KonnectGatewayControlPlane`

Use the `KonnectGatewayControlPlane` resource to define the {{site.konnect_short_name}} control plane that your CRDs will target. This enables your cluster to send configuration to {{site.konnect_short_name}}.

Apply the following configuration to define a Control Plane named `gateway-control-plane`:

<!-- vale off -->
{% konnect_crd %}
kind: KonnectGatewayControlPlane
apiVersion: konnect.konghq.com/{{ site.operator_konnectgatewaycontrolplane_api_version }}
metadata:
  name: gateway-control-plane
spec:
  createControlPlaneRequest:
    name: gateway-control-plane
  konnect:
    authRef:
      name: konnect-api-auth
{% endkonnect_crd %}
<!-- vale on -->

This resource links your cluster to a specific control plane instance in {{site.konnect_short_name}} using the credentials provided in `konnect-api-auth`.

{:.info}
> Make sure that the `KonnectGatewayControlPlane` resource is in the same namespace as the `KonnectAPIAuthConfiguration` resource.


## Bind the control plane using a `KonnectExtension`

To finalize the connection between your cluster and the {{site.konnect_short_name}} control plane, create a `KonnectExtension` object. This resource binds your local Gateway or data plane to the {{site.konnect_short_name}} control plane you've defined.

<!-- vale off -->
{% konnect_crd %}
kind: KonnectExtension
apiVersion: konnect.konghq.com/{{ site.operator_konnectextension_api_version }}
metadata:
  name: my-konnect-config
  namespace: kong
spec:
  clientAuth:
    certificateSecret:
      provisioning: Automatic
  konnect:
    controlPlane:
      ref:
        type: konnectNamespacedRef
        konnectNamespacedRef:
          name: gateway-control-plane
{% endkonnect_crd %}
<!-- vale on -->

The `KonnectExtension` resource handles automatic certificate generation and establishes secure communication between your cluster and {{site.konnect_short_name}}.

## Deploy a Dataplane

The Dataplane is the listener that will accept requests, and route traffic to your Kubernetes services.

```sh
echo '
apiVersion: gateway-operator.konghq.com/v1beta1
kind: DataPlane
metadata:
  name: dataplane
  namespace: kong
spec:
  extensions:
  - kind: KonnectExtension
    name: my-konnect-config
    group: konnect.konghq.com
  deployment:
    podTemplateSpec:
      spec:
        containers:
        - name: proxy
          image: kong/kong-gateway:3.13
          readinessProbe:
            initialDelaySeconds: 1
            periodSeconds: 1' | kubectl apply -f - 
```

## Validation

<!-- vale off -->
{% validation kubernetes-resource %}
kind: KonnectGatewayControlPlane
name: gateway-control-plane
{% endvalidation %}
<!-- vale on -->

Once these resources are in place, your cluster is connected to {{site.konnect_short_name}} and can begin managing entities such as `KongService`, `KongRoute`, and `KongPlugin`.
