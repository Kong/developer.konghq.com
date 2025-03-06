---
title: Get Started with decK
description: Learn how to install decK and use it to configure {{site.base_gateway}}
content_type: how_to
permalink: /deck/get-started/

related_resources: []

products:
  - gateway

plugins:
  - rate-limiting
  - key-auth

works_on:
  - on-prem
  - konnect

min_version:
  gateway: "3.4"

entities:
  - plugin
  - service
  - route
  - consumer

tags:
  - authentication

tldr:
  q: How do I use decK?
  a: Create a declarative configuration file named `kong.yaml` and run `deck gateway sync kong.yaml`

tools:
  - deck

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

This page teaches you how to use decK to create a Service, Route, Plugins, and Consumers. It uses the `deck gateway apply` command to build the configuration up incrementally. At any point, you can run `deck gateway dump` to see the entire configuration of {{ site.base_gateway }} at once.

## Create a Service

You can use decK to configure a Service by providing a `name` and a `url`. Any requests made to this Service will be proxied to `http://httpbin.konghq.com`:

{% entity_examples %}
entities:
  services:
  - name: example-service
    url: http://httpbin.konghq.com
{% endentity_examples %}

## Create a Route

To access this Service, you need to configure a Route. Create a Route that matches incoming requests that start with `/`, and attach it to the service that was previously created by specifying `service.name`:

{% entity_examples %}
entities:
  routes:
    - name: example-route
      service:
        name: example-service
      paths:
        - "/"
{% endentity_examples %}

You can now make a HTTP request to your running {{ site.base_gateway }} instance and see it proxied to httpbin:

{% validation request-check %}
url: '/anything'
status_code: 200
{% endvalidation %}

## Add rate limiting

At this point, {{ site.base_gateway }} is a transparent layer that proxies requests to the upstream httpbin instance. Let's add the [Rate Limiting](/plugins/rate-limiting/) plugin to make sure that people only make five requests per minute:

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      service: example-service
      config:
        minute: 5
        policy: local
{% endentity_examples %}

To see this in action, make six requests in rapid succession by pasting the following in to your terminal:

{% validation rate-limit-check %}
iterations: 6
url: '/anything'
{% endvalidation %}

## Add authentication

You may have noticed that the rate limiting plugin used the `limit_by: consumer` configuration option. This means that each uniquely identified consumer is allowed 5 requests per minute.

To identify a consumer, let's add the [Key Auth plugin](/plugins/key-auth/) and create a test user named `alice`:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-service
  consumers:
    - username: alice
      keyauth_credentials:
        - key: hello_world
{% endentity_examples %}

After applying the `key-auth` plugin, you need to provide the `apikey` header to authenticate your request:

{% validation request-check %}
url: '/anything'
status_code: 200
headers:
  - apikey:hello_world
{% endvalidation %}

If you make a request without the authentication header, you will see a `No API key found in request` message.

## See your decK file

This page provided each configuration snippet separately to focus on what each snippet provides. For production usage, you should apply the whole configuration each time.

To export the complete configuration, run `deck gateway dump -o kong.yaml`, then open `kong.yaml` in your favorite editor.

Try changing Alice's authentication key to `test` and then run `deck gateway sync kong.yaml` to sync the entire configuration. You'll see the following output:

```
creating key-auth test for consumer alice
deleting key-auth world for consumer alice
Summary:
  Created: 1
  Updated: 0
  Deleted: 1
```

Congratulations! You just went from zero to a configured {{ site.base_gateway }} using decK in no time at all.
