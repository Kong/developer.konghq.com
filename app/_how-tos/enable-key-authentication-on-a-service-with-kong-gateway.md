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

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
tldr:
    q: How do I secure a service with key authentication?
    a: Enable the Key Authentication plugin on the service. This plugin will require all requests made to this service to have a valid API key.

cleanup:
  inline:
    - title: Destroy the Kong Gateway container
      include_content: cleanup/products/gateway

---

## 1. Enable the Key Authentication plugin on the service:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-service
      config:
        key_names:
        - apikey
{% endentity_examples %}

## 2. Create a consumer

{% entity_examples %}
entities:
  consumers:
    - username: alex
      keyauth_credentials:
        - key: hello_world
{% endentity_examples %}

## 3. Validate

After configuring the Key Authentication plugin, you can verify that it was configured correctly and is working, by sending requests with and without the API key you created for your consumer.

This request should be successful:
```bash
curl --request GET \
 --url http://localhost:8000/example-route/anything \
 --header 'apikey: hello_world'
```

This request should return a `401 Unauthorized` error:

```bash
curl --request GET \
 --url http://localhost:8000/example-route/anything \
 --header 'apikey: another_key'
```
