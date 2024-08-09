---
title: Enable key authentication on a service with Kong Gateway
related_resources:
  - text: Authentication
    url: /authentication

products:
    - gateway

plugins:
    - key-auth

tags:
  - authentication
  - key-auth

content_type: tutorial

tools:
    - deck

prereqs:
    services:
        - example-service
    routes:
        - example-route

---

## Steps

1. Enable the Key Authentication plugin on the Service

{% capture step %}
{% entity_example %}
type: plugin
data:
  name: key-auth
  config:
    key_names:
    - apikey
targets:
- service
variables: 
    serviceName|Id: example-service
{% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Create a consumer

{% capture step %}
{% entity_example %}
type: consumer
data:
  username: alex
  keyauth_credentials:
  - key: hello_world
{% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Validate

   After configuring the Key Authentication plugin, you can verify that it was configured correctly and is working, by sending requests with and without the api key you created for your consumer.

   This request should be successful:
   ```bash
   curl --request GET \
    --url http://localhost:8000/example_route/anything \
    --header 'apikey: hello_world'
   ```

   This request should return a `401 Unauthorized` error:

   ```bash
   curl --request GET \
    --url http://localhost:8000/example_route/anything \
    --header 'apikey: another_key'
   ```

1. Teardown

   Destroy the Kong Gateway container.

   ```bash
   curl -Ls https://get.konghq.com/quickstart | bash -s -- -d
   ```
