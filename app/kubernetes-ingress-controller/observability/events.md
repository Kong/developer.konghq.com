---
title: Kubernetes Events

description: |
  {{ site.kic_product_name }} emits Kubernetes events to help you observe what's happening in your cluster.

content_type: reference
layout: reference
search_aliases:
  - kic events
tags: 
  - events
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Observability
related_resources:
  - text: Workspaces
    url: /kubernetes-ingress-controller/workspaces/
products:
  - kic

works_on:
  - on-prem
  - konnect

---


{{ site.kic_product_name }} provides Kubernetes Events to help understand the state of your system. Events occur when an invalid configuration is rejected by {{ site.base_gateway }} (`KongConfigurationApplyFailed`) or when an invalid configuration, such as an upstream service that doesn't exist, is detected (`KongConfigurationTranslationFailed`).

{:.info}
> The Events are not cleared immediately after you resolve the issues. The Event `count` stops increasing after you fix the problem. Events do eventually expire after an hour, by default, but may become outdated.

## Emitted Events

All the events emitted by {{site.kic_product_name}} are listed in the table below.

{% table %}
columns:
  - title: Reason
    key: reason
  - title: Type
    key: type
  - title: Meaning
    key: meaning
  - title: Involved objects
    key: objects
rows:
  - reason: "`KongConfigurationTranslationFailed`"
    type: "⚠️ Warning"
    meaning: "While translating Kubernetes resources into a {{site.base_gateway}} state, a conflict was detected. The involved object(s) were skipped to unblock building the {{site.base_gateway}} state without them."
    objects: "Any of the supported resources (e.g. `Ingress`, `KongPlugin`, `HTTPRoute`, etc.)"
  - reason: "`KongConfigurationApplyFailed`"
    type: "⚠️ Warning"
    meaning: "A {{site.base_gateway}} state built from Kubernetes resources was rejected by the {{site.base_gateway}} Admin API. The update of the configuration wasn't effective."
    objects: "In the case of a failure caused by a specific object, this can be any of the supported resources (e.g. `Ingress`, `KongPlugin`, `HTTPRoute`, etc.). When a specific causing object couldn't be identified, the event is attached to the {{site.kic_product_name}} Pod."
  - reason: "`KongConfigurationSucceeded`"
    type: "ℹ️ Normal"
    meaning: "A {{site.base_gateway}} state built from Kubernetes resources was successfully applied to the {{site.base_gateway}} Admin API."
    objects: "{{site.kic_product_name}} Pod."
  - reason: '{% new_in 3.2 %}<br /><br />`FallbackKongConfigurationTranslationFailed`'
    type: "⚠️ Warning"
    meaning: "During the translation of fallback Kubernetes resources into a {{site.base_gateway}} state, a conflict was detected. The involved object(s) were skipped to unblock building the {{site.base_gateway}} state without them."
    objects: "Any of the supported resources (e.g. `Ingress`, `KongPlugin`, `HTTPRoute`, etc.)"
  - reason: '{% new_in 3.2 %}<br /><br />`FallbackKongConfigurationApplyFailed`'
    type: "⚠️ Warning"
    meaning: "A fallback {{site.base_gateway}} state built from Kubernetes resources was rejected by the {{site.base_gateway}} Admin API. The update of the configuration wasn't effective."
    objects: "In the case of a failure caused by a specific object, this can be any of the supported resources (e.g. `Ingress`, `KongPlugin`, `HTTPRoute`, etc.). When a specific causing object couldn't be identified, the event is attached to the {{site.kic_product_name}} Pod."
  - reason: '{% new_in 3.2 %}<br /><br />`FallbackKongConfigurationSucceeded`'
    type: "ℹ️ Normal"
    meaning: "A fallback {{site.base_gateway}} state built from Kubernetes resources was successfully applied to the {{site.base_gateway}} Admin API."
    objects: "{{site.kic_product_name}} Pod."
{% endtable %}

### Finding problem resource Events

Once you see a translation or configuration push failure, you can locate which Kubernetes resources require changes by searching for Events. For example, this Ingress attempts to create a gRPC Route that also uses HTTP methods, which is an invalid configuration:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    konghq.com/methods: GET
    konghq.com/protocols: grpcs
    kubernetes.io/ingress.class: kong
  name: httpbin
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: httpbin
            port:
              number: 80
        path: /bar
        pathType: Prefix
```

{{site.base_gateway}} rejects the Route that {{site.kic_product_name}} creates from this Ingress and returns an error. {{site.kic_product_name}} processes this error and creates a Kubernetes Event linked to the Ingress.

You can find these Events by searching across all namespaces for Events with the reason {{site.kic_product_name}} provides for the failures:

```bash
kubectl get events -A --field-selector='reason=KongConfigurationApplyFailed'
```

The results should look like this:

```
NAMESPACE   LAST SEEN   TYPE      REASON                         OBJECT            MESSAGE
default     35m         Warning   KongConfigurationApplyFailed   ingress/httpbin   invalid methods: cannot set 'methods' when 'protocols' is 'grpc' or 'grpcs'
```

The controller can also create Events with the reason `KongConfigurationTranslationFailed` when it detects issues before sending configuration to {{site.base_gateway}}.

The complete Event contains additional information about the problem resource, the number of times the problem occurred, and when it occurred:

```yaml
apiVersion: v1
kind: Event
count: 1
firstTimestamp: "2023-02-21T22:42:48Z"
involvedObject:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  name: httpbin
  namespace: default
kind: Event
lastTimestamp: "2023-02-21T22:42:48Z"
message: 'invalid methods: cannot set ''methods'' when ''protocols'' is ''grpc''
  or ''grpcs'''
metadata:
  name: httpbin.1745f83aefeb8dde
  namespace: default
reason: KongConfigurationApplyFailed
reportingComponent: ""
reportingInstance: ""
source:
  component: kong-client
type: Warning
```

{{site.kic_product_name}} creates one Event for each problem with a resource, so you may see multiple Events for a single resource with different messages. The message describes the reason the resource is invalid. In this case, it's because gRPC routes cannot use HTTP methods.

### Events for cluster scoped resources

Kubernetes events are namespaced and created in the same namespace as the involved object. Cluster scoped objects are handled differently because they aren't assigned to a particular namespace.

`kubectl` and Kubernetes libraries, like `client-go`, assign the `default` namespace to events that involve cluster scoped resources.

For example, if you defined the following `KongClusterPlugin`, which has an incorrect schema:

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongClusterPlugin
config:
  config:
    latency_metrics: true
metadata:
  annotations:
    kubernetes.io/ingress.class: kong
  labels:
    global: "true"
  name: prometheus
plugin: prometheus
```

You can find the relevant event in the `default` namespace using the following `kubectl` command:

```bash
kubectl get events --field-selector involvedObject.name=prometheus -n default
```

This should output the following:

```bash
LAST SEEN   TYPE      REASON                         OBJECT                         MESSAGE
2s          Warning   KongConfigurationApplyFailed   kongclusterplugin/prometheus   invalid config.config: unknown field
```