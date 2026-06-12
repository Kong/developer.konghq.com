---
title: Set timeouts and retries for a Service
description: "Learn how to configure connection, read, and write timeouts and retry behavior on a Kubernetes Service using {{ site.operator_product_name }} annotations."
content_type: how_to

permalink: /operator/dataplanes/how-to/set-timeouts-and-retries/
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
  - on-prem
  - konnect

min_version:
  operator: '2.2'

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true
  inline:
    - title: Create Gateway resources
      include_content: /prereqs/operator/gateway
    - title: Create a Service and a Route
      include_content: /prereqs/operator/httpbin-service-route

tldr:
  q: How do I configure timeouts and retries for a Service with {{ site.operator_product_name }}?
  a: |
    Annotate the Kubernetes `Service` with `konghq.com/connect-timeout`, `konghq.com/read-timeout`, `konghq.com/write-timeout`, and `konghq.com/retries`. {{ site.base_gateway }} applies these settings when forwarding requests to the upstream service.

related_resources:
  - text: Service annotations reference
    url: /operator/dataplanes/reference/service-annotations/
---

Timeout and retry settings control how long {{site.base_gateway}} waits for responses from your upstream services and how many times it retries failed requests. You configure these settings by annotating the Kubernetes `Service` that your `HTTPRoute` routes traffic to.

## Annotate the Service

Annotate the `httpbin` Service with timeout and retry values:

```bash
kubectl annotate service httpbin -n kong \
  konghq.com/connect-timeout="3000" \
  konghq.com/read-timeout="5000" \
  konghq.com/write-timeout="5000" \
  konghq.com/retries="3"
```

The annotations have the following effects:

{% table %}
columns:
  - title: "Annotation"
    key: "annotation"
  - title: "Value"
    key: "value"
  - title: "Effect"
    key: "effect"
rows:
  - annotation: "`konghq.com/connect-timeout`"
    value: "`3000`"
    effect: "{{site.base_gateway}} waits up to 3 seconds to establish a TCP connection"
  - annotation: "`konghq.com/read-timeout`"
    value: "`5000`"
    effect: "{{site.base_gateway}} waits up to 5 seconds for the upstream to send a response"
  - annotation: "`konghq.com/write-timeout`"
    value: "`5000`"
    effect: "{{site.base_gateway}} waits up to 5 seconds when sending data upstream"
  - annotation: "`konghq.com/retries`"
    value: "`3`"
    effect: "Failed requests are retried up to 3 times before returning an error"
{% endtable %}

All timeout values are in milliseconds.

## Validate

1. Get the Gateway's external IP address:

   ```bash
   export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
   ```

1. Send a request that completes within the read timeout. The `/delay/1` endpoint waits 1 second before responding:

   ```bash
   curl -s -o /dev/null -w "%{http_code}" $PROXY_IP/httpbin/delay/1
   ```

   The response code should be `200`.

1. Send a request that exceeds the read timeout. The `/delay/10` endpoint waits 10 seconds:

   ```bash
   curl -s -o /dev/null -w "%{http_code}" $PROXY_IP/httpbin/delay/10
   ```

   The response code should be `504`, indicating that the upstream did not respond within the configured `read-timeout`.
