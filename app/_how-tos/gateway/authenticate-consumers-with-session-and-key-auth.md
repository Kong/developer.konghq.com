---
title: Authenticate Consumers with the Key Auth and Sessions plugins
permalink: /how-to/authenticate-consumers-with-session-and-key-auth/
content_type: how_to
description: Authenticate Consumers with key authentication and session cookies.
related_resources:
  - text: Authentication
    url: /authentication/

products:
    - gateway

entities: 
  - service
  - consumer
  - route

plugins:
    - key-auth
    - session
    - request-termination

tags:
  - authentication
  - key-auth
  - session

tools:
    - deck

works_on:
    - on-prem
    - konnect

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route

tldr:
    q: How do I authenticate Consumers with session cookies?
    a: |
      You can use the Session plugin, along with an authentication plugin like Key Authentication, to authenticate Consumers with session cookies. In summary, you need to:
      1. Configure the authentication plugin with credentials, an anonymous Consumer, and associate it with a Gateway Service. 
      2. Create a named Consumer with a credential for the authentication plugin, as well as an anonymous Consumer. 
      3. Configure the Session plugin and associate it with the Gateway Service, then configure the Request Termination plugin to prevent anonymous access.

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
---

## Enable the Key Authentication plugin

Authentication lets you identify a Consumer. In this tutorial, we'll be using the [Key Auth plugin](/plugins/key-auth/) for authentication, which allows users to authenticate with a key when they make a request.

Enable the plugin for the Gateway Service you created in the [prerequisites](#pre-configured-entities):

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      service: example-service
      config:
        key_names:
        - apikey
        anonymous: 81823632-10c0-4098-a4f7-31062520c1e6
{% endentity_examples %}
<!--vale on-->

## Create Consumers

[Consumers](/gateway/entities/consumer/) let you identify the client that's interacting with {{site.base_gateway}}. In this tutorial, we'll create one named Consumer with a credential as well as an anonymous Consumer to prevent [anonymous access](/gateway/authentication/#using-multiple-authentication-methods) with the Key Authentication plugin.

Create Consumers and an authentication credential for the named Consumer:

<!--vale off-->
{% entity_examples %}
entities:
  consumers:
    - username: alex
      keyauth_credentials:
        - key: hello_world
    - username: anonymous_users
      id: 81823632-10c0-4098-a4f7-31062520c1e6
{% endentity_examples %}
<!--vale on-->

## Enable the Session plugin

The [Session plugin](/plugins/session/) allows you to manage browser sessions for APIs proxied through the {{site.base_gateway}}.

We'll be setting `config.cookie_secure` to `false` for the sake of this tutorial so we don't have to use HTTPS, but in a production instance, leave this as the default value of `true`.

Enable the plugin for the Gateway Service you created in the [prerequisites](#pre-configured-entities):

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: session
      service: example-service
      config:
        storage: kong
        cookie_secure: false
{% endentity_examples %}
<!--vale on-->

## Enable the Request Termination plugin

In this tutorial, we'll be using the [Request Termination plugin](/plugins/request-termination/) to prevent unauthorized access by anonymous Consumers: 

<!--vale off-->
{% entity_examples %}
entities:
  plugins:
    - name: request-termination
      service: example-service
      consumer: anonymous_users
      config:
        status_code: 403
        message: 'Forbidden'
{% endentity_examples %}
<!--vale on-->

## Validate

After configuring the Key Authentication Encryption plugin, you can verify that it was configured correctly and is working by sending requests with and without the API key you created for your Consumer.

First, run the following to verify that anonymous requests return an error:

<!--vale off-->
{% validation unauthorized-check %}
url: /anything
status_code: 403
message: 'Forbidden'
{% endvalidation %}
<!--vale on-->

Then, run the following command to verify that a user can authenticate via sessions:

<!--vale off-->
{% validation request-check %}
url: /anything
headers:
  - 'apikey: hello_world'
message: OK
status_code: 200
extract_headers:
  - name: Set-Cookie
    variable: COOKIE_HEADER
{% endvalidation %}
<!--vale on-->

The response should now have the `Set-Cookie` header.
Make sure that this cookie works by copying the contents (for example: `session=emjbJ3MdyDsoDUkqmemFqw..|1544654411|4QMKAE3I-jFSgmvjWApDRmZHMB8.`) and exporting it in an environment variable:

```sh
export COOKIE_HEADER='YOUR-COOKIE-HEADER-HERE'
```

Use your session token in the request, but don't provide the API key. Even without the key, you will still be authenticated because {{site.base_gateway}} is using the session cookie granted by the Session plugin:
<!--vale off-->
{% validation request-check %}
url: /anything
headers:
  - 'cookie: $COOKIE_HEADER'
message: OK
status_code: 200
{% endvalidation %}
<!--vale on-->


