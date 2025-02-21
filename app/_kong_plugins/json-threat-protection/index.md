---
title: 'JSON Threat Protection'
name: 'JSON Threat Protection'

content_type: plugin

publisher: kong-inc
description: 'Apply size checks on JSON payload and minimize risk of content-level attacks'
tier: enterprise


products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.8'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: json-threat-protection.png

related_resources:
  - text: XML Threat Protection plugin
    url: /plugins/xml-threat-protection/
  - text: Injection Protection plugin
    url: /plugins/injection-protection/
  - text: Validate incoming JSON request bodies with JSON Threat Protection
    url: /how-to/validate-incoming-json-request-bodies/

categories:
  - security

search_aliases:
  - json threat protection
  - json-threat-protection
---

The JSON Threat Protection plugin validates and protects against malicious or overly complex JSON payloads. This includes JSON-based injection attacks, oversized payload attacks, and malformed JSON leading to application crashes. 

Enabling this plugin is recommended for any API that accepts JSON input, especially public APIs with user-submitted data and high-traffic APIs vulnerable to DDoS attacks using large payloads.

## How it works

The JSON Threat Protection plugin validates incoming requests with a JSON body against policy limits that you've configured for the plugin, regardless of whether the `Content-Type` header exists or is set to `application/json`. If a request violates the policy limits, you can configure it to either block the request (block mode) or monitor and log it (tap mode).

The plugin checks the following limits:

- Maximum container depth of the entire JSON
- Maximum number of array elements
- Maximum number of object entries
- Maximum length of object keys
- Maximum length of strings

Additionally, you can set a policy that restricts the JSON body size (`max_body_size`). When this is configured, the plugin compares the `Content-Length` header with `max_body_size`. In block mode, if the `Content-Length` header is missing or its value exceeds `max_body_size`, the request will be terminated. In tap mode, only the body size is checked and logs are recorded.

{:.info}
> **Notes**: 
> * Length calculation for JSON strings and object entry names is based on UTF-8 characters, not bytes.
> * `max_body_size` and `nginx_http_client_max_body_size` are independent of each other. Therefore, if `nginx_http_client_max_body_size` is set to a larger value while `max_body_size` is smaller and block mode is enabled, any request with a body size greater than `max_body_size` but less than `nginx_http_client_max_body_size` will be terminated.

### Example JSON body violation

If you had the following policy set:

- Maximum container depth: 2
- Maximum number of array elements: 2
- Maximum number of object entries: 4
- Maximum length of object keys: 7 
- Maximum length of strings: 6


The following JSON would meet the policy standards:

```json
{
  "name": "Jason",
  "age": 20,
  "gender": "male",
  "parents": ["Joseph", "Viva"]
}
```

But the following JSON wouldn't meet the policy standards:

```json
{
  "username": "longusername",                    
  "age": 123456,                                 
  "items": ["item1", "item2", "item3", "item4"], 
  "address": {
    "street": "1234 Some Long Street Name",      
    "city": "LongCityName",                      
    "country": {
      "name": "CountryNameTooLong",              
      "code": "LongCode12345"                    
    },
    "postal_code": "1234567890123456789"        
  },
  "extra_field": "this_is_a_long_value"          
}
```

This JSON body violates the policy in the following ways:

| Policy | Violation description |
|--------|-----------------------|
| Maximum container depth: 2 | The `country` object is nested within the `address` object, exceeding the maximum depth of 2. |
| Maximum number of array elements: 2 | The `items` array has 4 elements. |
| Maximum number of object entries: 4 | The `address` object has 4 keys: `street`, `city`, `country`, and `postal_code`, which is allowed. But the root object has 5 keys: `username`, `age`, `items`, `address`, and `extra_field`. |
| Maximum length of object keys: 7 | The key `postal_code`, which has a string length of 11, exceeds the maximum string length of the object name. |
| Maximum length of strings: 6 | Several string values (like `longusername`, `CountryNameTooLong`, and `this_is_a_long_value`) exceed the maximum allowed string length of 6. |


## Log JSON request body violations
In tap mode, if the plugin detects violations in the JSON request body, it logs a warning and proxies the request to the upstream service instead of blocking the request. In other words, in tap mode, the plugin only monitors the traffic.

To enable tap mode, set `config.enforce_mode` to `log_only`.


