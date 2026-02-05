---
title: Support multiple authentication methods
description: "Enable multiple authentication methods on a single Service"
content_type: how_to

permalink: /kubernetes-ingress-controller/multiple-auth-methods/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: How To

related_resources:
  - text: mTLS in KIC
    url: /kubernetes-ingress-controller/mtls/
search_aliases:
  - kic mtls
products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I enable multiple authentication methods on a single Kubernetes Service?
  a: Create an `anonymous` consumer that will be used when validation fails. Attach a `request-termination` plugin to this consumer to ensure that traffic is blocked if the request does not match another consumer's credentials.

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - echo-service

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## Allowing multiple authentication methods

The default behavior for {{site.base_gateway}} authentication plugins is to require credentials for all requests even if a request has been authenticated through another plugin. Configure an anonymous Consumer on your authentication plugins to set authentication options.

## Create Consumers

Create two [Consumers](/gateway/entities/consumer/) that use different authentication methods:

* `consumer-1` uses `basic-auth`
* `consumer-2` uses `key-auth`

1. Create a secret to add a `basic-auth` credential for `consumer-1`:

    ```bash
    echo '
    apiVersion: v1
    kind: Secret
    metadata:
      name: consumer-1-basic-auth
      namespace: kong
      labels:
        konghq.com/credential: basic-auth
    stringData:
        username: consumer-1
        password: consumer-1-password
    ' | kubectl apply -f -
    ```

1. Create a secret to add a `key-auth` credential for `consumer-2`:

    ```bash
    echo '
    apiVersion: v1
    kind: Secret
    metadata:
      name: consumer-2-key-auth
      namespace: kong
      labels:
        konghq.com/credential: key-auth
    stringData:
      key: consumer-2-password
    ' | kubectl apply -f -
    ```

1.  Create a Consumer named `consumer-1`:

{% entity_example %}
type: consumer
data:
  username: consumer-1
  credentials:
    - consumer-1-basic-auth
  
indent: 4
{% endentity_example %}

1.  Create a Consumer named `consumer-2`:

{% entity_example %}
type: consumer
data:
  username: consumer-2
  credentials:
    - consumer-2-key-auth
  
indent: 4
{% endentity_example %}

## Secure the service

Once the Consumers and credentials are created, you can add authentication plugins to your Service.

First, create a [`key-auth`](/plugins/key-auth/) plugin. Notice the `anonymous` configuration option, which means that if no credentials match, the consumer named `anonymous` is assigned to the request:

{% entity_example %}
type: plugin
data:
  name: key-auth
  config:
    anonymous: anonymous
  
  service: echo
  skip_annotate: true
{% endentity_example %}

As Consumer 2 is using `basic-auth`, we also need to create a [`basic-auth`](/plugins/basic-auth/) plugin:

{% entity_example %}
type: plugin
data:
  name: basic-auth
  config:
    anonymous: anonymous
  
  service: echo
  other_plugins: key-auth
{% endentity_example %}

## Create an anonymous Consumer

Your endpoints are now secure, but neither Consumer can access the endpoint when providing valid credentials. This is because each plugin will verify the Consumer using it’s own authentication method.

To allow multiple authentication methods, create an anonymous Consumer which is the default user if no valid credentials are provided:

{% entity_example %}
type: consumer
data:
  username: anonymous
{% endentity_example %}

All requests to the API will now succeed as the anonymous Consumer is being used as a default.

To secure the API once again, add a request termination plugin to the anonymous Consumer that returns HTTP 401:

{% entity_example %}
type: plugin
data:
  name: request-termination
  config:
    message: "Authentication required"
    status_code: 401
  
  consumer: anonymous
{% endentity_example %}

## Create an HTTPRoute

To route HTTP traffic, you need to create an `HTTPRoute` or an `Ingress` resource pointing at your Kubernetes `Service`.

<!--vale off-->
{% httproute %}
name: echo
matches:
  - path: /echo
    service: echo
    port: 1027
skip_host: true
{% endhttproute %}
<!--vale on-->

## Validate your configuration

Once the resource has been reconciled, you'll be able to call the `/echo` endpoint and {{ site.base_gateway }} will route the request to the `echo` service.

Let's check that authentication works.

Try to access the Gateway Service via the `/anything` Route using a nonsense API key:

{% validation request-check %}
url: '/echo'
status_code: 401
headers:
  - apikey:nonsense
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The request should now fail with a `401` response and your configured error message, as this Consumer is considered anonymous.

You should get the same result if you try to access the Route without any API key:

{% validation request-check %}
url: '/echo'
status_code: 401
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

Finally, try accessing the Route with the configured basic auth credentials:

{% validation request-check %}
url: '/echo'
user: "consumer-1:consumer-1-password"
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

This time, authentication should succeed with a `200`.
