---
title: 'Customize a 404 error message'
permalink: /how-to/transform-a-404-response-message/
content_type: how_to


description: Use the Exit Transformer plugin to transform a 404 response before returning it to the client.

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - exit-transformer

entities: 
  - service
  - route
  - plugin

tags:
    - transformations

tldr:
    q: How can I use modify a 404 response before returning it to the client?
    a: Enable the [Exit Transformer](/plugins/exit-transformer/) plugin, configure a Lua function with the transformation you want to perform, and set the `config.handle_unknown` parameter to `true`.

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

---

## Enable the Exit Transformer plugin

In this example, we want to customize the message that the client will receive when the requested Route isn't found.
To do this, we'll use the [Exit Transformer plugin](/plugins/exit-transformer/). To transform `404` responses, we need to set the `handle_unknown` parameter to `true`, and then specify the transformations to perform using one or multiple Lua functions. 

In this case, we'll create a function that:
* Replaces the existing error message with a custom one
* Changes the response body structure to include `error: true` and the status code

{% entity_examples %}
entities:
  plugins:
  - name: exit-transformer
    config: 
      handle_unknown: true
      functions:
      - 'return function(status, body, headers)
          if status == 404 then
            local new_body = {
                error = true,
                status = status,
                message = "This is not the Route you are looking for",
            }
            return status, new_body, headers
          else
            return status, body, headers
          end
         end'
{% endentity_examples %}


## Validate

To check that the response transformation is working, send a request to a Route that doesn't exist. For example:

{% validation request-check %}
url: /something
status_code: 404
headers:
    - 'Accept: application/json'
{% endvalidation %}

The response should contain the customized message.