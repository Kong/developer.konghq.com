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
---

The Kong Response Size Limiting plugin lets you block upstream responses where the body is greater than a specific size in megabytes.

If the body is greater than configured size, proxy consumers will receive the HTTP status code 413 and the message body `"Response size limit exceeded"`.

{:.warning}
> **Note**: This plugin currently accomplishes response limiting by validating the `Content-Length` header on upstream responses.
If the upstream service lacks the response header, then this plugin will allow the response to pass.

## Install the Kong Response Size Limiting plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="kong-response-size-limiting" %}
