---
title: Allow clients to choose their authentication methods and prevent unauthorized access
permalink: /how-to/allow-multiple-authentication/
content_type: how_to
related_resources:
  - text: Authentication
    url: /gateway/authentication/

description: Learn how to allow different clients to access an upstream service with different authentication types, and forbid access to any unauthenticated clients.

products:
    - gateway

plugins:
  - basic-auth
  - key-auth
  - request-termination

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.4'

entities: 
  - plugin
  - service
  - route
  - consumer

tags:
  - authentication

tldr:
  q: How do I allow different clients to access an upstream service with different authentication types, and forbid access to any unauthenticated clients?
  a: |
    Configure multiple authentication plugins, like [Key Auth](/plugins/key-auth/) and [Basic Auth](/plugins/basic-auth/), and apply them to specific [Consumers](/gateway/entities/consumer/). Set `config.anonymous` in those plugins to the ID of the anonymous Consumer to catch access attempts from anyone else.
    Then, apply the [Request Termination](/plugins/request-termination/) plugin to the anonymous Consumer to terminate the requests and send back a specific message.

faqs:
  - q: What happens if I configure multiple authentication methods but don't use an anonymous Consumer?
    a: |
      If `config.anonymous` isn't set, then all configured authentication plugins will attempt to authenticate every request. 
      For example, if you have Key Auth and Basic Auth configured on a Gateway Service, then every request has to contain **both** types of authentication. 
      In this case, the last plugin executed is the one setting the credentials passed to the upstream service. 

  - q: What if I configure an anonymous Consumer but don't add request termination?
    a: |
      When multiple authentication plugins are enabled on a Gateway Service and `config.anonymous` is set without any request termination, unauthorized requests will be allowed through. 
      If you want anonymous access to be forbidden, you **must** configure the Request Termination plugin on the anonymous Consumer.
  - q: Can I use the anonymous Consumer with OpenID Connect?
    a: |
      If you are using the [OpenID Connect](/plugins/openid-connect/) plugin for handling Consumer authentication, you must set both [`config.anonymous`](/plugins/openid-connect/reference/#schema--config-anonymous) and [`config.consumer_claim`](/plugins/openid-connect/reference/#schema--config-consumer-claim) in the plugin's configuration, as setting `config.anonymous` alone doesn't map that Consumer.
  
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

## Create Consumers

You can use multiple authentication plugins with an anonymous Consumer to give clients multiple options for authentication. 
The anonymous Consumer doesn't correspond to any real user, and acts as a fallback to catch all other unauthorized requests.

Create three Consumers, including the `anonymous` Consumer:

{% entity_examples %}
entities:
  consumers:
    - username: anonymous
    - username: Dana
    - username: Mahan
{% endentity_examples %}

We're going to assign a different authentication type to each Consumer later.

## Set up authentication

Add the Key Auth and Basic Auth plugins to the `example-service` Gateway Service, and set the `anonymous` fallback to the Consumer we created earlier:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-service
      config:
        hide_credentials: true
        anonymous: anonymous
    - name: basic-auth
      service: example-service
      config:
        hide_credentials: true
        anonymous: anonymous
{% endentity_examples %}

## Test with anonymous Consumer

You now have authentication enabled on the Gateway Service, but the `anonymous` Consumer also allows requests from unauthenticated clients.

The following validation works because the unauthenticated request falls back to the anonymous Consumer, which allows it through:

{% validation request-check %}
url: '/anything'
status_code: 200
display_headers: true
{% endvalidation %}

The following validation with fake credentials also works because an incorrect API key is treated as anonymous:

{% validation request-check %}
url: '/anything'
status_code: 200
display_headers: true
headers:
  - apikey:nonsense
{% endvalidation %}

In both cases, you should get a 200 response, as the `anonymous` Consumer is allowed.

## Configure credentials

Now, let's configure Consumers with different auth credentials and prevent unauthenticated access. Configure different credentials for the two named users: basic auth for `Dana`, and key auth for `Mahan`:

{% entity_examples %}
entities:
  consumers:
    - username: Dana
      basicauth_credentials:
        - username: Dana
          password: dana
    - username: Mahan
      keyauth_credentials:
        - key: mahan
{% endentity_examples %}


## Add Request Termination to the anonymous Consumer

The anonymous Consumer gets no credentials, as we don't want unauthenticated users accessing our Gateway Service.
Instead, you can configure the Request Termination plugin to handle anonymous Consumers and redirect their requests with a `401`:

{% entity_examples %}
entities:
  consumers:
    - username: anonymous
      plugins:
        - name: request-termination
          config:
            status_code: 401
            message: '"Error - Authentication required"'
{% endentity_examples %}

## Validate authentication

Let's check that authentication works.

Try to access the Gateway Service via the `/anything` Route using a nonsense API key:

{% validation request-check %}
url: '/anything'
status_code: 401
display_headers: true
headers:
  - apikey:nonsense
{% endvalidation %}

The request should now fail with a `401` response and your configured error message, as this Consumer is considered anonymous.

You should get the same result if you try to access the Route without any API key:

{% validation request-check %}
url: '/anything'
status_code: 401
display_headers: true
{% endvalidation %}

Finally, try accessing the Route with the configured basic auth credentials:

{% validation request-check %}
url: '/anything'
user: "Dana:dana"
status_code: 200
display_headers: true
{% endvalidation %}

This time, authentication should succeed with a `200`.
