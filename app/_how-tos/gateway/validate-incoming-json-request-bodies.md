---
title: Validate incoming JSON request bodies with JSON Threat Protection
permalink: /how-to/validate-incoming-json-request-bodies/
description: Use the JSON Threat Protection plugin to enforce a JSON threat protection policy. 
content_type: how_to
related_resources:
  - text: "{{site.base_gateway}} Security"
    url: /gateway/security/

products:
    - gateway

works_on:
    - on-prem
    - konnect

entities: 
  - plugin
  - service
  - route

plugins:
  - json-threat-protection

tags:
    - security

tldr:
    q: How do I ensure that the JSON payload in incoming requests adheres to policy limits?
    a: Enable the [JSON Threat Protection plugin](/plugins/json-threat-protection/) on a Route to enforce payload limits and reject violating requests.

faqs:
  - q: How can I enable a JSON threat protection policy without blocking non-conforming requests? 
    a: |
      You can enable the JSON Threat Protection plugin in tap mode by setting `config.enforcement_mode` to `log_only`.
      In tap mode, the plugin still inspects the JSON body but only logs warnings instead of blocking violations, and still proxies the request to the upstream service.

tools:
  - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.8'
---

## Create a JSON threat protection policy

Configure the JSON Threat Protection plugin on the `example-route` Route to set limits on the contents of incoming request bodies.

In the following example, we enable the plugin in `block` mode, which will reject any requests that don't conform to the policy, 
and instead respond with a `400` error and the message `Incorrect request format`:

{% entity_examples %}
entities:
  plugins:
    - name: json-threat-protection
      route: example-route
      config:
        max_body_size: 1024
        max_container_depth: 2
        max_object_entry_count: 4
        max_object_entry_name_length: 7
        max_array_element_count: 2
        max_string_value_length: 6
        enforcement_mode: block
        error_status_code: 400
        error_message: "Incorrect request format"
{% endentity_examples %}

## Validate the policy

Let's make a valid request. The following request conforms to the policy that we just created:

{% validation request-check %}
url: '/anything'
headers:
  - "Content-Type: application/json"
body:
  name: Jason
  age: 20
  gender: male
  parents:
   - Joseph
   - Viva
method: POST
status_code: 200
display_headers: true
{% endvalidation %}

You should get a `200` response, and the request gets proxied to the upstream service.

Now, try a request with a payload that doesn't conform to the policy:

{% validation request-check %}
url: '/anything'
headers:
  - "Content-Type: application/json"
body:
  name: Jason
  age: 20
  gender: male
  parents:
   - Antonio
   - Viva
method: POST
status_code: 400
display_headers: true
{% endvalidation %}

In this case, the string `Antonio` is longer than the maximum allowed string length of 6, so the request is blocked.
The plugin returns a `400` response and the message `Incorrect request format`.