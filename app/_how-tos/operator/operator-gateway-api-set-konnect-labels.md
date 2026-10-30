---
title: Set {{site.konnect_short_name}} labels on control planes and data planes with {{site.operator_product_name}}
description: Set custom labels on the {{site.konnect_short_name}} control planes and data plane nodes created for hybrid Gateways using Gateway API annotations.
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
    Add the `konghq.com/konnect-cp-labels` and `konghq.com/konnect-dp-labels` annotations to your `Gateway` or `GatewayClass` resources, using the format `key1=value1,key2=value2`. When both resources set the same key, the value from the `Gateway` is used.

prereqs:
  operator:
    konnect:
      auth: true

related_resources:
  - text: Provision a Hybrid Gateway in {{site.konnect_short_name}}
    url: /operator/get-started/gateway-api/deploy-gateway/
  - text: "{{site.konnect_short_name}} labels"
    url: /konnect-platform/konnect-labels/
---

[{{site.konnect_short_name}} labels](/konnect-platform/konnect-labels/) are key-value pairs that you can attach to control planes and data plane nodes to organize and filter them. When {{site.operator_product_name}} provisions a hybrid Gateway, you can set these labels with the following annotations on the `Gateway` or `GatewayClass` resource:

* `konghq.com/konnect-cp-labels`: Sets labels on the {{site.konnect_short_name}} control plane created for the `Gateway`. {{site.operator_product_name}} writes them to `spec.createControlPlaneRequest.labels` of the generated `KonnectGatewayControlPlane`.
* `konghq.com/konnect-dp-labels`: Sets labels on the {{site.konnect_short_name}} data plane nodes of the `Gateway`. {{site.operator_product_name}} writes them to `spec.konnect.dataPlane.labels` of the generated `KonnectExtension`.

Each annotation takes a comma-separated list of labels, with the key and value of each label separated by `=`. For example: `env=prod,team=platform`.

Labels set on a `GatewayClass` apply to every `Gateway` that uses the class. Labels set on a `Gateway` are merged with the labels from its `GatewayClass`. When both set the same key, the value from the `Gateway` is used.

## Create the GatewayConfiguration and GatewayClass resources

Configure the `GatewayConfiguration` resource with your {{site.konnect_short_name}} authentication, and configure the `GatewayClass` resource to reference it. The annotations on the `GatewayClass` define default labels for all `Gateway` resources that use this class:

```sh
echo '
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
---
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
    namespace: kong ' | kubectl apply -f -
```

## Create a Gateway that overrides labels

Create a `Gateway` resource that references the `GatewayClass`. The `Gateway` annotations override the `env` label from the `GatewayClass` and add an `owner` label to the control plane:

```sh
echo '
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
    port: 80' | kubectl apply -f -
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

{:.info}
> If your `GatewayConfiguration` uses an existing control plane (`spec.konnect.source: Mirror`), {{site.operator_product_name}} doesn't manage that control plane, so it ignores the `konghq.com/konnect-cp-labels` annotation. The `konghq.com/konnect-dp-labels` annotation still applies to the data plane nodes.

## Validate

Check that the `Gateway` is programmed:

{% validation kubernetes-resource %}
kind: Gateway
name: hybrid
namespace: kong
{% endvalidation %}

To check the control plane labels, fetch the control planes that have the `owner: payments` label in {{site.konnect_short_name}}:

<!--vale off-->
{% konnect_api_request %}
url: /v2/control-planes?labels=owner:payments
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->

The response contains the control plane created for the `Gateway`, with the `env: prod`, `team: platform`, and `owner: payments` labels in its `labels` field.

To check the data plane labels, get the labels from the `KonnectExtension` that {{site.operator_product_name}} created for the `Gateway`:

```sh
kubectl get konnectextension -n kong -o jsonpath='{.items[*].spec.konnect.dataPlane.labels}'
```

You should see the following output:

```json
{"env":"prod","region":"us-west"}
```
{:.no-copy-code}

The data plane nodes connected to the control plane show the same labels in {{site.konnect_short_name}} API Gateway.

## Limitations

Labels set through annotations have the following limitations:

* Each annotation can contain at most 5 labels on the `Gateway` and at most 5 labels on the `GatewayClass`. The merged result for each annotation can't exceed 5 labels either. For example, if the `GatewayClass` sets 3 control plane labels and the `Gateway` sets 3 other control plane labels, the merged result has 6 labels and is rejected.
* Each label must contain exactly one `=`, and the key can't be empty. Because `,` separates labels and `=` separates the key from the value, keys and values can't contain these characters.
* Spaces around keys and values are removed.
* The `konghq.com/konnect-cp-labels` annotation only applies to control planes that {{site.operator_product_name}} creates. It's ignored when the `GatewayConfiguration` mirrors an existing control plane.

Labels must also meet the following requirements, which are based on the [{{site.konnect_short_name}} label requirements](/konnect-platform/konnect-labels/#label-requirements):

<!--vale off-->
{% table %}
columns:
  - title: Requirement
    key: requirement
  - title: Control plane labels
    key: cp
  - title: Data plane labels
    key: dp
rows:
  - requirement: Key and value length
    cp: 1 to 63 characters
    dp: 1 to 63 characters
  - requirement: Allowed characters in keys
    cp: Alphanumeric characters, `-`, `_`, and `.`. Must begin and end with an alphanumeric character.
    dp: Alphanumeric characters, `-`, `_`, and `.`. Must begin and end with an alphanumeric character.
  - requirement: Allowed characters in values
    cp: Can't contain `,` or `=`. {{site.operator_product_name}} only checks the length, so make sure values also follow the {{site.konnect_short_name}} label requirements.
    dp: Alphanumeric characters, `-`, `_`, and `.`. Must begin and end with an alphanumeric character.
  - requirement: Reserved key prefixes
    cp: "`k8s`, `kong`, `konnect`, `mesh`, `kic`, `insomnia`, `_`"
    dp: "`kong`, `konnect`, `mesh`, `kic`, `insomnia`, `_`"
  - requirement: Reserved keys
    cp: "`managed-by`, which {{site.operator_product_name}} sets on the control plane"
    dp: None
{% endtable %}
<!--vale on-->

### Troubleshoot invalid labels

If an annotation is malformed, contains too many labels, or contains an invalid key or value, {{site.operator_product_name}} doesn't apply any labels from that annotation and sets the `Programmed` condition of the `Gateway` to `False`. The reason for the error is reported in one of the following `Gateway` conditions, with the reason `InvalidKonnectLabels`:

* `KonnectGatewayControlPlaneProgrammed` for the `konghq.com/konnect-cp-labels` annotation
* `KonnectExtensionReady` for the `konghq.com/konnect-dp-labels` annotation

For example, if the `Gateway` sets 6 control plane labels, you get the following condition:

<!--vale off-->
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
<!--vale on-->

{{site.operator_product_name}} doesn't retry the `Gateway` while the annotation is invalid. Fix the annotation on the `Gateway` or `GatewayClass` to trigger a new reconciliation.
