---
title: Prometheus metrics reference

description: |
  Understand which metrics {{ site.kic_product_name }} exposes in Prometheus format

content_type: reference
layout: reference

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Observability

products:
  - kic

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Prometheus and Grafana guide
    url: /kubernetes-ingress-controller/observability/prometheus-grafana/

---

Both {{site.kic_product_name}} and {{site.base_gateway}} expose Prometheus metrics:

* {{site.kic_product_name}} exposes Prometheus metrics for configuration updates.
* {{site.base_gateway}} can expose Prometheus metrics for the requests that are served if the [Prometheus plugin](/plugins/prometheus/) is enabled. See [integration with Prometheus and Grafana](/kubernetes-ingress-controller/observability/prometheus-grafana) for a complete example.

## {{ site.kic_product_name }} metrics

{{site.kic_product_name}} exposes the following Prometheus metrics:

{{site.kic_product_name}} exposes the following Prometheus metrics:

### ingress_controller_configuration_push_count

`ingress_controller_configuration_push_count` (type: `counter`) provides the number of successful or failed configuration pushes to {{site.base_gateway}}.

This metric provides these labels:

* `protocol` describes the configuration protocol in use, which can be `db-less` or `deck`.
* `success` logs the status of configuration updates. If `success` is `false`, an unrecoverable error occurred.  If `success` is `true`, the push succeeded with no errors.
* `failure_reason` is populated if `success="false"`. It describes the reason for the failure:
    * `conflict`: A configuration conflict that must be manually fixed
    * `network`: A network related issues, such as {{site.base_gateway}} is offline
    * `other`: Other issues, such as {{site.base_gateway}} reporting a non-conflict error
* `dataplane` describes the Data Plane that was the target of configuration push.

### ingress_controller_translation_count

`ingress_controller_translation_count` (type: `counter`) provides the number of translations from the Kubernetes state to the {{site.base_gateway}} state.

This metric provides the `success` label. `success` logs the status of configuration updates. If `success` is `false`, an unrecoverable error occurred.
If `success` is `true`, the translation succeeded with no errors.

### ingress_controller_translation_duration_milliseconds {% new_in 3.3 %}

`ingress_controller_translation_duration_milliseconds` (type: `histogram`) is the amount of time, in milliseconds, that
it takes to translate the Kubernetes state to the {{site.base_gateway}} state.

This metric provides the `success` label. `success` logs the status of the translation. If `success` is `false`, an unrecoverable error occurs. If `success` is `true`, the translation succeeded without errors.

### ingress_controller_configuration_push_duration_milliseconds

`ingress_controller_configuration_push_duration_milliseconds` (type: `histogram`) is the amount of time, in milliseconds, that it takes to push the configuration to {{site.base_gateway}}.

This metric provides these labels:

* `protocol` describes the configuration protocol in use, which can be `db-less` or `deck`.
* `dataplane` describes the Data Plane that was the target of configuration push.
* `success` logs the status of configuration updates. If `success` is `false`, an unrecoverable error occurred.  If `success` is `true`, the push succeeded with no errors.

### ingress_controller_configuration_push_size {% new_in 3.4 %}

`ingress_controller_configuration_push_size` (type: `gauge`) is the size of the configuration pushed to {{site.base_gateway}}, in bytes.

This metric provides these labels:

* `dataplane` describes the Data Plane that was the target of the configuration push.
* `protocol` describes the configuration protocol (metric is presented for `db-less`, for `deck` it doesn't exist) in use.
* `success` describes whether there were unrecoverable errors (`false`) or not (`true`).

### ingress_controller_configuration_push_broken_resource_count

`ingress_controller_configuration_push_broken_resource_count` (type: `counter`) provides the number of resources not accepted by {{site.base_gateway}} when attempting to push configuration.

This metric provides the `dataplane` label. This specifies the Data Plane that was the target of the configuration push.

### ingress_controller_configuration_push_last_successful

`ingress_controller_configuration_push_last_successful` (type: `gauge`) provides the time of the last successful configuration push.

This metric provides the `dataplane` label. This specifies the Data Plane that was the target of the configuration push.

### ingress_controller_translation_broken_resource_count

`ingress_controller_translation_broken_resource_count` (type: `gauge`) provides the number of resources that the controller cannot successfully translate to {{site.base_gateway}} configuration.

### ingress_controller_fallback_translation_count {% new_in 3.2 %}

`ingress_controller_fallback_translation_count` (type: `counter`) provides the count of translations from Kubernetes state to {{site.base_gateway}} state in fallback mode.

This metric provides the `success` label. `success` logs the status of the translation. If `success` is `false`, an unrecoverable error occurs. If `success` is `true`, the translation succeeded without errors.

### ingress_controller_fallback_translation_duration_milliseconds {% new_in 3.3 %}

`ingress_controller_fallback_translation_duration_milliseconds` (type: `histogram`) provides the amount of time, in milliseconds, 
that it takes to translate the Kubernetes state to the {{site.base_gateway}} state in fallback mode.

This metric provides the `success` label. `success` logs the status of the translation. If `success` is `false`, an unrecoverable error occurs. If `success` is `true`, the translation succeeded without errors.

### ingress_controller_fallback_translation_broken_resource_count

`ingress_controller_fallback_translation_broken_resource_count` (type: `gauge`) provides the number of resources that the controller cannot successfully translate to {{site.base_gateway}} configuration in fallback mode.

### ingress_controller_fallback_configuration_push_count

`ingress_controller_fallback_configuration_push_count` (type: `counter`) provides the count of successful/failed fallback configuration pushes to {{site.base_gateway}}.

This metric provides these labels:

* `dataplane` describes the Data Plane that was the target of the configuration push.
* `protocol` describes the configuration protocol in use, which can be `db-less` or `deck`.
* `success` logs the status of configuration updates. If `success` is `false`, an unrecoverable error occurs. If `success` is `true`, the push succeeded without errors.
* `failure_reason` is populated if `success="false"`. It describes the reason for the failure:
  * `conflict`: A configuration conflict that must be manually fixed
  * `network`: A network related issue, such as {{site.base_gateway}} being offline
  * `other`: Other issues, such as {{site.base_gateway}} reporting a non-conflict error

### ingress_controller_fallback_configuration_push_last

`ingress_controller_fallback_configuration_push_last` (type: `gauge`) provides the time of the last successful fallback configuration push.

This metric provides the `dataplane` label. `dataplane` describes the Data Plane that was the target of the configuration push.

### ingress_controller_fallback_configuration_push_duration_milliseconds

`ingress_controller_fallback_configuration_push_duration_milliseconds` (type: `histogram`) provides the amount of time, in milliseconds, that it takes to push the fallback configuration to {{site.base_gateway}}.

This metric provides these labels:

* `dataplane` describes the Data Plane that was the target of the configuration push.
* `protocol` describes the configuration protocol in use, which can be `db-less` or `deck`.
* `success` logs the status of configuration updates. If `success` is `false`, an unrecoverable error occurs. If `success` is `true`, the push succeeded without errors.

### ingress_controller_fallback_configuration_push_size {% new_in 3.4 %}

`ingress_controller_fallback_configuration_push_size` (type: `gauge`) is the size of the configuration pushed to {{site.base_gateway}} in fallback mode, in bytes.

This metric provides these labels:

* `dataplane` describes the Data Plane that was the target of the configuration push.
* `protocol` describes the configuration protocol (metric is presented for `db-less`, for `deck` it doesn't exist) in use.
* `success` describes whether there were unrecoverable errors (`false`) or not (`true`).

### ingress_controller_fallback_configuration_push_broken_resource_count

`ingress_controller_fallback_configuration_push_broken_resource_count` (type: `gauge`) provides the number of resources that {{site.base_gateway}} doesn't accept when attempting to push the fallback configuration.

This metric provides the `dataplane` label. `dataplane` describes the Data Plane that was the target of the configuration push.

### ingress_controller_fallback_cache_generation_duration_milliseconds

`ingress_controller_fallback_cache_generation_duration_milliseconds` (type: `histogram`) provides the amount of time, in milliseconds, that it takes to generate a fallback cache.

This metric provides the `success` label. `success` logs the status of cache generation. If `success` is `false`, an unrecoverable error occurs. If `success` is `true`, the cache generation succeeded without errors.

### ingress_controller_processed_config_snapshot_cache_hit

`ingress_controller_processed_config_snapshot_cache_hit` (type: `counter`) provides the count of times the controller hit the processed configuration snapshot cache and skipped generating a new one.

### ingress_controller_processed_config_snapshot_cache_miss

`ingress_controller_processed_config_snapshot_cache_miss` (type: `counter`) provides the count of times the controller missed the processed configuration snapshot cache and had to generate a new one.

## Low-level performance metrics

In addition, {{site.kic_product_name}} exposes more low-level performance metrics, but these may change from version to version because they are provided by the underlying frameworks of {{site.kic_product_name}}.

A non-exhaustive list of these low-level metrics is described in the following:
* [Controller-runtime metrics](https://github.com/kubernetes-sigs/controller-runtime/blob/master/pkg/internal/controller/metrics/metrics.go)
* [Workqueue metrics](https://github.com/kubernetes/component-base/blob/release-1.20/metrics/prometheus/workqueue/metrics.go#L29)