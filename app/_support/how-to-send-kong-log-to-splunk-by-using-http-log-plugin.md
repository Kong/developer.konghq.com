---
title: How to send Kong log to Splunk by using HTTP Log plugin
content_type: support
description: Configure the HTTP Log plugin to send Kong logs to a Splunk HTTP Event Collector (HEC) raw endpoint using a secure token.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: HTTP Log plugin
    url: /plugins/http-log/
  - text: HTTP Log plugin log format
    url: /plugins/http-log/#log-format
  - text: Splunk HEC examples
    url: https://docs.splunk.com/Documentation/Splunk/9.0.2/Data/HECExamples
tldr:
  q: How do I send Kong logs to Splunk using the HTTP Log plugin?
  a: |
    Configure the HTTP Log plugin's `http_endpoint` to point at your Splunk HEC raw endpoint (for example `https://<splunk-host>:8088/services/collector/raw`), and set the `Authorization` header to `Splunk <token>`. On Kong versions before 3.0, the `Authorization` header value must be given as a list rather than a plain string.
---

## Overview

How to send Kong log to Splunk by using the HTTP Log plugin?

## Steps

Please note the example below is for Splunk 9.0.2. Check the Splunk docs to use the appropriate method if you are using a different version of Splunk.

The HTTP Log plugin will send the response body in the plugin log format.

We could follow example 3 and send the raw data to the `/services/collector/raw` endpoint of Splunk.

Also, the secure token is required by Splunk with this endpoint.

Assuming our Splunk is running at `https://demo.splunkcloud.com:8088/` and its secure token is `123456`, then we could enable an HTTP Log plugin with the configuration below:

```yaml
config:
  headers:
    Authorization: "Splunk 123456"
  http_endpoint: https://demo.splunkcloud.com:8088/services/collector/raw
  method: POST
  timeout: 3000
  retry_count: 1
```

If you are running Kong version less than 3.0, please enable an HTTP Log plugin with the configuration below instead:

```yaml
config:
  headers:
    Authorization:
      - "Splunk 123456"
  http_endpoint: https://demo.splunkcloud.com:8088/services/collector/raw
  method: POST
  timeout: 3000
  retry_count: 1
```

This HTTP Log plugin will send the log to `https://demo.splunkcloud.com:8088/services/collector/raw` with the secure token, as in example 3 of the Splunk HEC examples.
