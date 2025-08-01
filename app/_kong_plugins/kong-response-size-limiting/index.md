---
title: 'Kong Response Size Limiting'
name: 'Kong Response Size Limiting'

content_type: plugin

publisher: optum
description: 'Block responses with bodies greater than a specified size'

products:
    - gateway

works_on:
    - on-prem

icon: optum.png

search_aliases:
    - optum

third_party: true

support_url: https://github.com/Optum/kong-response-size-limiting/issues

source_code_url: https://github.com/Optum/kong-response-size-limiting/

license_type: Apache-2.0

min_version:
  gateway: '1.0'
---

The Kong Response Size Limiting plugin blocks upstream responses with a body size that exceeds a specified limit in megabytes.

When a response exceeds the configured size, the client receives an HTTP `413` status code and the message body: `Response size limit exceeded`.

{:.warning}
> **Note**: This plugin enforces limits based on the `Content-Length` header in the upstream response.  
> If the upstream service does not include this header, the plugin cannot enforce the limit and the response will be allowed.

## Install the Kong Response Size Limiting plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="kong-response-size-limiting" %}
