---
title: 'Kong Service Virtualization'
name: 'Kong Service Virtualization'

content_type: plugin

publisher: optum
description: "Mock virtual API request and response pairs through {{site.base_gateway}}"

products:
    - gateway

works_on:
    - on-prem

third_party: true

support_url: https://github.com/Optum/kong-service-virtualization/issues

source_code_url: https://github.com/Optum/kong-service-virtualization

license_type: Apache-2.0

icon: optum.png

search_aliases:
  - optum

min_version:
  gateway: '1.0'
---

The Kong Service Virtualization plugin enables mocking virtual API request and responses using {{site.base_gateway}}.

## How it works

You can pass a set of mock request attributes to this plugin. 
For example, let's say you configure two test cases:

```yaml
_format_version: "3.0"
plugins:
  - name: kong-service-virtualization
    config:
      virtual_tests:
      - name: TestCase1
        requestHttpMethod: POST
        requestHash: '0296217561490155228da9c17fc555cf9db82d159732f3206638c25f04a285c4'
        responseHttpStatus: '200'
        responseContentType: application/json
        response: eyJtZXNzYWdlIjogIkEgQmlnIFN1Y2Nlc3MhIn0=
      - name: TestCase2
        requestHttpMethod: GET
        requestHash: e2c319e4ef41706e2c0c1b266c62cad607a014c59597ba662bef6d10a0b64a32
        responseHttpStatus: '200'
        responseContentType: application/json
        response: eyJtZXNzYWdlIjogIkFub3RoZXIgU3VjY2VzcyEifQ==
```

In this configuration:
* `TestCase1` and `TestCase2` are the names of the virtual test cases and must be passed in as a header value:
`X-VirtualRequest: TestCase1` or `X-VirtualRequest: TestCase2`.
* The `requestHash` parameter value is a SHA256 (HTTP Request as query parameters or HTTP Body).
* The `response` parameter value is a Base64 encoded format of the response HTTP Body.

This plugin configuration would equate to the following request:

```json
POST:
{
   "virtual": "test"
}
Response : {"message": "A Big Success!"} as base64 encoded in plugin

GET:
hello=world&service=virtualized
Response : {"message": "Another Success!"} as base64 encoded in plugin
```

## Error states and debugging

If you don't successfully match on request, you will receive a SHA256 comparison that you can use for debugging:

```json
Status Code: 404 Not Found
Content-Length: 207
Content-Type: application/json; charset=utf-8

{"message":"No virtual request match found, your request yielded: 46c4b4caf0cc3a5a589cbc4e0f3cd0492985d5b889f19ebc11e5a5bd6454d20f expected 0296217561490155228da9c17fc555cf9db82d159732f3206638c25f04a285c4"}
```

If the test case specified in the header doesn't match anything found stored within the plugin, you will get the following error:

```json
Status Code: 404 Not Found
Content-Length: 49
Content-Type: application/json; charset=utf-8

{"message":"No matching virtual request found!"}
```

## Install the Kong Service Virtualization plugin

{% include_cached /plugins/install-third-party.md name=page.name slug=page.slug rock="kong-service-virtualization" %}