---
title: Set {{site.konnect_short_name}} labels on control planes and data planes with {{site.operator_product_name}}
description: Use Gateway API annotations to set custom labels on the {{site.konnect_short_name}} control planes and data plane nodes that {{site.operator_product_name}} creates for hybrid Gateways.
content_type: how_to

permalink: /operator/konnect/crd/gateway/labels/

breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect

products:
  - operator

works_on:
  - konnect

min_version:
  operator: '2.4'

tags:
  - konnect-crd

tldr:
  q: How can I add custom labels to {{site.konnect_short_name}} control planes and data planes created for my Gateways?
  a: |
    Add the `konghq.com/konnect-cp-labels` and `konghq.com/konnect-dp-labels` annotations to your `Gateway` or `GatewayClass` resources, using the format `key1=value1,key2=value2`. When both resources set the same key, the `Gateway` value takes precedence.

prereqs:
  operator:
    konnect:
      auth: true

related_resources:
  - text: Provision a Hybrid Gateway in {{site.konnect_short_name}}
    url: /operator/get-started/gateway-api/deploy-gateway/
  - text: "{{site.konnect_short_name}} labels"
    url: /konnect-platform/konnect-labels/
  - text: Labeling and tagging resources with {{site.operator_product_name}}
    url: /operator/konnect/labelling/
  - text: Reference an existing control plane
    url: /operator/konnect/crd/control-planes/mirror/
  - text: Check the status of a Gateway
    url: /operator/dataplanes/troubleshooting/status/#gateway

faqs:
  - q: How many labels can I set, and which keys and values are allowed?
    a: |
      Each annotation can contain at most 5 labels on the `Gateway` and 5 on the `GatewayClass`, and the merged result can't exceed 5 labels. Keys and values can't contain `,` or `=`, and some key prefixes are reserved. For the full list of limitations and requirements, see [Labels on hybrid Gateways](/operator/konnect/labelling/#labels-on-hybrid-gateways).
  - q: Can I set labels on an existing control plane?
    a: |
      No. If your `GatewayConfiguration` uses an existing control plane (`spec.konnect.source: Mirror`), {{site.operator_product_name}} doesn't manage that control plane, so it ignores the `konghq.com/konnect-cp-labels` annotation. The `konghq.com/konnect-dp-labels` annotation still applies to the data plane nodes.
  - q: Why aren't my labels applied in {{site.konnect_short_name}}?
    a: |
      If an annotation is malformed, contains too many labels, or contains an invalid key or value, {{site.operator_product_name}} doesn't apply any labels from that annotation and sets the `Programmed` condition of the `Gateway` to `False`. {{site.operator_product_name}} reports the error in one of the following `Gateway` conditions, with the reason `InvalidKonnectLabels`:

      * `KonnectGatewayControlPlaneProgrammed` for the `konghq.com/konnect-cp-labels` annotation
      * `KonnectExtensionReady` for the `konghq.com/konnect-dp-labels` annotation

      For example, if the `Gateway` sets 6 control plane labels, the `Gateway` has the following condition:

      ```json
      {
        "lastTransitionTime": "2026-10-30T10:15:42Z",
        "message": "invalid konghq.com/konnect-cp-labels annotation: Gateway kong/hybrid: too many labels: 6 exceeds the maximum of 5",
        "observedGeneration": 2,
        "reason": "InvalidKonnectLabels",
        "status": "False",
        "type": "KonnectGatewayControlPlaneProgrammed"
      }
      ```
      {:.no-copy-code}

      {{site.operator_product_name}} doesn't retry the `Gateway` while the annotation is invalid. Fix the annotation on the `Gateway` or `GatewayClass` to trigger a new reconciliation.
---

[{{site.konnect_short_name}} labels](/konnect-platform/konnect-labels/) are key-value pairs that you can attach to control planes and data plane nodes to organize and filter them. To label the control plane and data plane nodes of a [hybrid `Gateway`](/operator/get-started/gateway-api/deploy-gateway/), add the following annotations to the `Gateway` or its `GatewayClass`:

* `konghq.com/konnect-cp-labels`: Labels for the control plane
* `konghq.com/konnect-dp-labels`: Labels for the data plane nodes

Each annotation takes a comma-separated list of `key=value` pairs, for example `env=prod,team=platform`. Labels on a `GatewayClass` apply to every `Gateway` that uses the class. When both set the same key, the `Gateway` value takes precedence. For limits and requirements, see [Labels on hybrid Gateways](/operator/konnect/labelling/#labels-on-hybrid-gateways).

## Create the GatewayConfiguration and GatewayClass resources

Create a `GatewayConfiguration` resource with your {{site.konnect_short_name}} authentication:

<!--vale off-->
{% konnect_crd %}
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: hybrid
  namespace: kong
spec:
  konnect:
    authRef:
      name: konnect-api-auth
  dataPlaneOptions:
    deployment:
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: kong/kong-gateway:{{ site.data.gateway_latest.release }}
{% endkonnect_crd %}
<!--vale on-->

Create a `GatewayClass` resource that references the `GatewayConfiguration`. The annotations on the `GatewayClass` define default labels for all `Gateway` resources that use the class:

<!--vale off-->
{% konnect_crd %}
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: hybrid
  annotations:
    konghq.com/konnect-cp-labels: "env=dev,team=platform"
    konghq.com/konnect-dp-labels: "env=dev,region=us-west"
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: hybrid
    namespace: kong
{% endkonnect_crd %}
<!--vale on-->

Wait for the `GatewayClass` to be accepted:

```bash
kubectl wait gatewayclass/hybrid \
  --for=condition=Accepted=True \
  --timeout=5m
```

## Create a Gateway that overrides labels

Create a `Gateway` resource that references the `GatewayClass`. The `Gateway` annotations override the `env` label from the `GatewayClass` and add an `owner` label to the control plane:

<!--vale off-->
{% konnect_crd %}
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: hybrid
  namespace: kong
  annotations:
    konghq.com/konnect-cp-labels: "env=prod,owner=payments"
    konghq.com/konnect-dp-labels: "env=prod"
spec:
  gatewayClassName: hybrid
  listeners:
  - name: http
    protocol: HTTP
    port: 80
{% endkonnect_crd %}
<!--vale on-->

Wait for the `Gateway` to be programmed:

```bash
kubectl wait gateway/hybrid -n kong \
  --for=condition=Programmed=True \
  --timeout=10m
```

{{site.operator_product_name}} merges the labels from the `GatewayClass` and the `Gateway`, and applies the following labels in {{site.konnect_short_name}}:

<!--vale off-->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: Labels
    key: labels
rows:
  - resource: Control plane
    labels: "`env: prod`, `team: platform`, `owner: payments`"
  - resource: Data plane nodes
    labels: "`env: prod`, `region: us-west`"
{% endtable %}
<!--vale on-->

{{site.operator_product_name}} keeps the labels in sync with the annotations. If you change the annotations on the `Gateway` or `GatewayClass` later, {{site.operator_product_name}} updates the labels in {{site.konnect_short_name}}.

## Validate

To check the control plane labels, fetch the control planes that have the `owner: payments` label in {{site.konnect_short_name}}:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes?labels=owner:payments
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

The response contains the control plane that {{site.operator_product_name}} created for the `Gateway`, with the `env: prod`, `team: platform`, and `owner: payments` labels in its `labels` field.

To check the data plane labels, get the labels from the `KonnectExtension` that {{site.operator_product_name}} created for the `Gateway`:

```sh
kubectl get konnectextension -n kong -o jsonpath='{.items[*].spec.konnect.dataPlane.labels}'
```

The command returns the following output:

```json
{"env":"prod","region":"us-west"}
```
{:.no-copy-code}

The data plane nodes connected to the control plane show the same labels in {{site.konnect_short_name}}.
