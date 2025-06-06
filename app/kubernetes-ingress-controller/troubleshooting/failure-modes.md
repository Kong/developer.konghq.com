---
title: "Failure modes"

description: |
  Learn about the different ways {{ site.kic_product_name }} can fail.

content_type: reference
layout: reference

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Troubleshooting

products:
  - kic

works_on:
  - on-prem
  - konnect

tags:
  - troubleshooting

related_resources:
  - text: "Debugging {{site.base_gateway}} configuration"
    url: /kubernetes-ingress-controller/troubleshooting/kong-gateway-configuration/
  - text: Debugging Kubernetes API Server connectivity
    url: /kubernetes-ingress-controller/troubleshooting/kubernetes-api-server/
  - text: "Debugging KIC in {{site.konnect_short_name}}"
    url: /kubernetes-ingress-controller/troubleshooting/konnect/
  - text: "Debugging {{site.kic_product_name}}"
    url: /kubernetes-ingress-controller/troubleshooting/debugging/
---

This reference describes the different types of {{site.kic_product_name}} failure modes and how it processes them.

When you run {{site.kic_product_name}}, you can encounter the following failures:

{% table %}
columns:
  - title: Error example
    key: error
  - title: Failure mode
    key: mode
rows:
- error: "`Reconciler error` in logs"
  mode: "[Errors in reconciling Kubernetes resources](#errors-in-reconciling-kubernetes-resources)"
- error: |
    Non-existent service referenced by an `Ingress`

    *Example:* `Ingress` with a non-existent backend service
  mode: "[Failures in translating configuration](#failures-in-translating-configuration)"
- error: |
    {{site.base_gateway}} rejected configuration 
    
    *Example:* `Ingress` with invalid regex in the path
  mode: "[Failures in applying configuration to {{site.base_gateway}}](#failures-in-applying-configuration-to-kong-gateway)"
- error: |
    Errors when sending configuration to {{site.konnect_short_name}} 

    *Example:* Failed request logs
  mode: "[Failures in uploading configuration to {{site.konnect_short_name}}](#failures-in-uploading-configuration-to-konnect)"
{% endtable %}

{{site.kic_product_name}} uses different methods to process each failure type, and creates error logs or other evidence, like Prometheus metrics and Kubernetes events, so you can observe and track the failures.


## Errors in reconciling Kubernetes resources

When the controllers reconciling a specific kind of Kubernetes resource run into errors in reconciling the resource, a `Reconciler error` log line is recorded and the resource is re-queued for another round of reconciliation. 

The `controller_runtime_reconcile_errors_total` Prometheus metric stores the total number of reconcile errors per controller from the start of {{site.kic_product_name}}. Search for the `Reconciler error` keyword in the {{site.kic_product_name}} container logs to see detailed errors.

## Failures in translating configuration

When {{site.kic_product_name}} finds Kubernetes resources that can't be correctly translated to {{site.base_gateway}} configuration (for example, an `Ingress` is using a non-existent `Service` as its backend), a translation failure is generated with the namespace and name of the objects causing the failure.

The Kubernetes objects causing translation failures aren't translated to {{site.base_gateway}} configuration in the translation process. You can use Kubernetes events and Prometheus metrics to observe the translation failures.  If {{site.kic_product_name}} is integrated with {{site.konnect_short_name}}, it will report that a translation error happened in the uploading node status.

{:.info}
> Translation errors don't prevent {{ site.kic_product_name }} from generating a configuration for {{ site.base_gateway }}. Once the resources can be translated, they will be added to the configuration.

{{site.kic_product_name}} collects all translation failures and generates a Kubernetes `Event` with the `Warning` type and the `KongConfigurationTranslationFailed` reason for each causing object in a translation failure. Prometheus metrics could also reflect the statistics of translation failures: 

* `ingress_controller_translation_broken_resource_count` is the number of translation failures that happened in the latest translation
* `ingress_controller_translation_count` with the `success=false` label is the total number of translation procedures where translation failures happened

You can use `kubectl get events -n <namespace> --field-selector reason="KongConfigurationTranslationFailed"` to fetch events generated for translation failures. For example, if an `Ingress` named `ing-1` in the namespace `test` used a non-existent `Service` as its backend, you could get the event with the following command:

```bash
kubectl get events -n test --field-selector reason="KongConfigurationTranslationFailed"
```

The response would look like this:
```
LAST SEEN   TYPE      REASON                               OBJECT                    MESSAGE
18m         Warning   KongConfigurationTranslationFailed   ingress/ing-1   failed to resolve Kubernetes Service for backend: failed to fetch Service test/httpbin-deployment-1: Service test/httpbin-deployment-1 not found
```
{:.no-copy-code}

## Failures in applying configuration to {{site.base_gateway}}

When {{site.kic_product_name}} fails to apply translated {{site.base_gateway}} configuration to {{site.base_gateway}}, {{site.kic_product_name}} will try to recover from the failure and record the failure into logs, Kubernetes events, and Prometheus metrics.  Recovery usually fails because the translated configuration is rejected by {{site.base_gateway}}.

If {{site.kic_product_name}} fails to apply the translated configuration, it then tries to apply the last successful {{site.base_gateway}} configuration to new instances of {{site.base_gateway}} to attempt a best effort at making them available.

If the `FallbackConfiguration` feature gate is enabled, {{site.kic_product_name}} discovers the Kubernetes objects that caused the invalid configuration, and tries to build a fallback configuration from valid objects and parts of the last valid configuration that are built from the broken objects. See [fallback configuration](/kubernetes-ingress-controller/fallback-configuration/) for more information.

### Debugging configuration failures

You can observe failures in applying configuration from Kubernetes events and Prometheus metrics:

* {{site.kic_product_name}} generates an event with the `Warning` type and the `KongConfigurationApplyFailed` reason attached to the pod itself when it fails to apply the configuration. 
* For each object that causes the invalid configuration, {{site.kic_product_name}} generates a `Warning` event type and the `KongConfigurationApplyFailed` reason attached to the object. 
* The Prometheus metric `ingress_controller_configuration_push_count` with the `success=false` label shows the total number of failures from applying the configuration by reason and URL of {{site.base_gateway}} Admin API. 
* The Prometheus metric `ingress_controller_configuration_push_broken_resource_count` reflects the number of Kubernetes resources that caused the error in the last configuration push.

For example, let's say you create an `Ingress` with the `ImplementationSpecific` path type and an invalid regex in `Path` (which can only be only be done when the validating webhook is disabled, otherwise it will be rejected by the webhook):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    konghq.com/strip-path: "true"
  name: ingress-invalid-regex
  namespace: default
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - backend:
          service:
            name: httpbin-deployment
            port:
              number: 80
        path: /~^^/a$
        pathType: ImplementationSpecific
```

You can get the Kubernetes events:

```bash
kubectl get events --all-namespaces --field-selector reason=KongConfigurationApplyFailed
```

Both the events attached to the invalid ingress and attached to the {{site.kic_product_name}} pod are recorded:
```
NAMESPACE   LAST SEEN   TYPE      REASON                         OBJECT                                 MESSAGE
default     2m9s        Warning   KongConfigurationApplyFailed   ingress/ingress-invalid-regex          invalid paths.1: should start with: / (fixed path) or ~/ (regex path)
kong        15s         Warning   KongConfigurationApplyFailed   pod/kong-controller-779cb796f4-7q7c2   failed to apply Kong configuration to https://10.244.1.43:8444: HTTP status 400 (message: "failed posting new config to /config")
```
{:.no-copy-code}

To see more details about the `HTTP 400` error, enable the [dump config](/kubernetes-ingress-controller/troubleshooting/kong-gateway-configuration/#dumping-generated-kong-configuration) setting on the controller.

## Failures in uploading configuration to {{site.konnect_short_name}}

When {{site.kic_product_name}} is integrated with {{site.konnect_short_name}} and it fails to send configuration to {{site.konnect_short_name}}, it generates error logs for failed requests, records the failures to Prometheus metrics, and updates the node status of itself in {{site.konnect_short_name}}: 

* {{site.kic_product_name}} parses errors returned from {{site.konnect_short_name}} when uploading the configuration fails. It logs a line at the error level for each {{site.base_gateway}} entity that failed to create/update/delete, with the message `Failed to send request to Konnect`. 
* The Prometheus metrics `ingress_controller_configuration_push_count` and `ingress_controller_configuration_push_duration_milliseconds_bucket` can also reflect configuration upload failures to {{site.konnect_short_name}}, where the `dataplane` label is the URL of {{site.konnect_short_name}}.

For more information about debugging {{ site.konnect_short_name }}, see [debugging KIC in {{ site.konnect_short_name }}](/kubernetes-ingress-controller/troubleshooting/konnect/).