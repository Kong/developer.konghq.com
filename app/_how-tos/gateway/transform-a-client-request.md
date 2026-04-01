---
title: Transform a client request in {{site.base_gateway}}
permalink: /how-to/transform-a-client-request/
content_type: how_to

description: Use the Request Transformer Advanced plugin to transform a client request before proxying it.

products:
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.4'

plugins:
  - request-transformer-advanced

entities: 
  - service
  - route
  - plugin

tags:
    - transformations

tldr:
    q: How can I transform a client request before proxying it?
    a: Enable the [Request Transformer Advanced](/plugins/request-transformer-advanced/) plugin and configure any combination of `config.remove`, `config.rename`, `config.replace`, `config.add`, `config.append`, and `config.allow` to configure the transformation to perform.

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

related_resources:
  - text: All transformation plugins
    url: /plugins/?category=transformations

---

## Enable the Request Transformer Advanced plugin

In this example, we expect the client to send requests with a JSON body containing customer details and a query parameter containing a customer ID.

We want to transform the request to:
* Specify a list of allowed JSON properties to ensure that only the expected properties are received by the upstream server
* Remove the customer ID from the query string and add it to the JSON body instead

Configure the [Request Transformer Advanced](/plugins/request-transformer-advanced) plugin with the transformations to perform:

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: request-transformer-advanced
      config:
        allow:
          body:
            - customer_id
            - customer_name
            - customer_zipcode
        remove:
          querystring:
            - customer_id
        add:
          body:
            - 'customer_id:$(query_params["customer_id"])'         
{% endentity_examples %}
<!--vale on-->


## Validate

To check that the request transformation is working, send a `POST` request with the `customer_id` as a query parameter and extra JSON properties in the request body:

<!--vale off-->
{% validation request-check %}
url: /anything?customer_id=abc123
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
body:
  customer_name: 'Jane Smith'
  customer_zipcode: '41563'
  customer_phone: 555-555-5555
{% endvalidation %}
<!--vale on-->

In this example, we're using [httpbin.konghq.com/anything](https://httpbin.konghq.com/#/Anything/post_anything) as the upstream. It returns anything that is passed to the request, which means the response contains the transformed request body received by the upstream:
```json
{
   "json":{
      "customer_id": "abc123", 
      "customer_name": "Jane Smith", 
      "customer_zipcode": "41563"
   }
}
```
{:.no-copy-code}