---
title: Deploy sidecars
description: "Deploy sidecar containers alongside {{ site.base_gateway }} using PodTemplateSpec"
content_type: how_to

permalink: /operator/dataplanes/how-to/deploy-sidecars/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"

products:
  - operator

works_on:
  - konnect
  - on-prem
 
tldr:
  q: How do I deploy a sidecar container for {{ site.base_gateway }} with {{ site.operator_product_name }}?
  a: Use PodTemplateSpec to customize the spec and specify an additional container in `spec.containers`.

---

## Deploy Sidecar

{{ site.operator_product_name }} uses [PodTemplateSpec](/operator/dataplanes/reference/podtemplatespec/) to customize deployments.

Here is an example that deploys a [Vector](https://vector.dev/) sidecar alongside the proxy containers.

## Configure vector.dev

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: sidecar-vector-config
data:
  vector.toml: |
    [sources.proxy_access_log_source]
    type = "file"
    include = [ "/etc/kong/log/proxy_access.log" ]
    [sinks.proxy_access_log_sink]
    type = "console"
    inputs = [ "proxy_access_log_source" ]
    encoding.codec = "json"
```

## Configure PodTemplateSpec

<!--vale off-->
{% operator_podtemplatespec_example %}
dataplane:
  metadata:
    labels:
      dataplane-pod-label: example
    annotations:
      dataplane-pod-annotation: example
  spec:
    volumes:
    - name: cluster-certificate
    - name: sidecar-vector-config-volume
      configMap:
        name: sidecar-vector-config
    - name: proxy-logs
      emptyDir:
        sizeLimit: 128Mi
    containers:
    - name: sidecar
      image: timberio/vector:0.31.0-debian
      volumeMounts:
      - name: sidecar-vector-config-volume
        mountPath: /etc/vector
      - name: proxy-logs
        mountPath: /etc/kong/log/
      readinessProbe:
        initialDelaySeconds: 1
        periodSeconds: 1
    - name: proxy
      image: 'kong/kong-gateway:{{ site.data.gateway_latest.release }}'
      volumeMounts:
      - name: proxy-logs
        mountPath: /etc/kong/log/
      env:
      - name: KONG_LOG_LEVEL
        value: debug
      - name: KONG_PROXY_ACCESS_LOG
        value: /etc/kong/log/proxy_access.log
{% endoperator_podtemplatespec_example %}
<!--vale on-->
