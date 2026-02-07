---
title: Add Correlation IDs to {{site.base_gateway}} logs
permalink: /how-to/add-correlation-ids-to-gateway-logs/
content_type: how_to
description: Learn how to add correlation IDs to logs with the Correlation ID plugin.
tools:
  - deck

products:
    - gateway

works_on:
    - on-prem
tags:
  - transformations
  - logging

plugins:
  - correlation-id

related_resources:
  - text: "{{site.base_gateway}} logs"
    url: /gateway/logs/
tldr:
    q: How do I add Correlation IDs to my {{site.base_gateway}} logs?
    a: |
        Define the log format in the `nginx_http_log_format` parameter, and use `$http_{header_name}` to reference the header defined in the [Correlation ID plugin](/plugins/correlation-id/) (`$http_Kong_Request_ID` for the default header name). Reference the name of the format to use in the [`proxy_access_log`](/gateway/configuration/#proxy-access-log) parameter.

prereqs:
  skip_product: true
  inline:
    - title: "{{site.base_gateway}} license"
      include_content: prereqs/gateway-license
      icon_url: /assets/icons/gateway.svg

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

## Start {{site.base_gateway}}

Create the {{site.base_gateway}} container with the following environment variables:
* `KONG_NGINX_HTTP_LOG_FORMAT`: Defines the log format to use. In this example, we'll name the format `correlation_id_log`, and include for each request:
  * The time of the request
  * The method and endpoint
  * The status
  * The value of the header that contains the Correlation ID, `Kong-Request-ID` in this example
* [`KONG_PROXY_ACCESS_LOG`](/gateway/configuration/#proxy-access-log): Specifies the log output file and the log format to use

```sh
curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA \
   -e "KONG_NGINX_HTTP_LOG_FORMAT=correlation_id_log '\$time_iso8601 - \$request - \$status - Kong-Request-ID: \$http_Kong_Request_ID'" \
   -e "KONG_PROXY_ACCESS_LOG=/dev/stdout correlation_id_log"
```

## Enable the Correlation ID plugin

Enable the [Correlation ID](/plugins/correlation-id/) plugin to generate a UUID with a counter in a `Kong-Request-ID` header:
{% entity_examples %}
entities:
  plugins:
    - name: correlation-id
      config:
        header_name: Kong-Request-ID
        generator: uuid#counter
{% endentity_examples %}

## Create a Service and a Route

To validate the configuration, we need to create a Gateway Service and a Route:
<!--vale off -->
{% entity_examples %}
entities:
  services:
    - name: example-service
      url: http://httpbin.konghq.com/anything
  routes:
    - name: example-route
      paths:
        - /anything
      service: 
        name: example-service
{% endentity_examples %}
<!--vale on -->

## Send a request

Send a request to the Route we created to generate a log entry:
<!--vale off -->
{% validation request-check %}
url: '/anything'
status_code: 200
display_headers: true
{% endvalidation %}
<!--vale on -->
You should see a `Kong-Request-ID` header in the response.

## Validate

To validate, check your {{site.base_gateway}} logs. 
You should see an entry in the format we defined. For example:
```
2025-04-18T17:44:12+00:00 - GET /anything HTTP/1.1 - 200 - Kong-Request-ID: 8b899f70-2804-44f5-a8be-910bc03c8b00#1
```
{:.no-copy-code}
