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

---

## Prerequisites 

place holder for prerendered prereq instructions that contains: 

* Docker: Docker is used to run a temporary Kong Gateway and database to allow you to run this tutorial
* curl: curl is used to send requests to Kong Gateway
* Kong Gateway

## Steps

1. Get Kong

    Run Kong Gateway with the quickstart script:
    ```bash
    curl -Ls https://get.konghq.com/quickstart | bash -s
    ```

    Once the Kong Gateway is ready, you will see the following message:

    ```bash
    Kong Gateway Ready 
    ```

1. Create a service 

{% capture step %}
{% entity_example %}
formats:
    - deck
type: service
data:
   name: example_service
{% endentity_example %}
{% endcapture %}
{{ step | indent: 3}}

1. Create a route 

{% capture step %}
{% entity_example %}
formats:
    - deck
type: route
data:
  name: example_route
{% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Enable the Key Authentication plugin on the Service

{% capture step %}
{% entity_example %}
formats:
    - deck
type: plugin
data:
  name: key-auth
  config:
    key_names:
    - apikey
targets:
- service
{% endentity_example %}
{% endcapture %}
{{ step | indent: 3 }}

1. Create a consumer

{% capture step %}
{% entity_example %}
formats:
    - deck
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