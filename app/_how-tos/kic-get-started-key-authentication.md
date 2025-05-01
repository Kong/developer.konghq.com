---
title: Key Authentication
description: |
  Add key authentication to a Kubernetes Service using the KongPlugin resource
content_type: how_to

permalink: /kubernetes-ingress-controller/get-started/key-authentication/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Get Started

series:
  id: kic-get-started
  position: 5

tldr:
  q: How do I secure my service using {{ site.kic_product_name }}?
  a: |
    Create a `KongPlugin` resource containing an authentication plugin configuration and annotate your Kubernetes service with the plugin name

    ```bash
    kubectl annotate service YOUR_SERVICE konghq.com/plugins=key-auth
    ```

products:
  - kic

tools:
  - kic

works_on:
  - on-prem
  - konnect

prereqs:
  skip_product: true
---

## Understanding authentication

Authentication is the process of verifying that a requester has permissions to access a resource. An API gateway can authenticate the flow of data to and from your upstream services. 

{{site.base_gateway}} has a library of plugins that support the most widely used [methods of API gateway authentication](/plugins/?category=authentication). 

Common authentication methods include:
* Key Authentication
* Basic Authentication
* OAuth 2.0 Authentication
* LDAP Authentication Advanced
* OpenID Connect

### Authentication benefits

With {{site.base_gateway}} controlling authentication, requests won't reach upstream services unless the client has successfully authenticated. This means upstream services process pre-authorized requests, freeing them from the cost of authentication, which is a savings in compute time *and* development effort.

{{site.base_gateway}} has visibility into all authentication attempts and enables you to build monitoring and alerting capabilities which support service availability and compliance. 

For more information, see [What is API Gateway Authentication?](https://konghq.com/learning-center/api-gateway/api-gateway-authentication).

## Add authentication to the echo service

1. Create a new `key-auth` plugin.

{% entity_example %}
type: plugin
indent: 4
data:
  name: key-auth
  
  service: echo
  other_plugins: rate-limit-5-min
{% endentity_example %}

1. Test that the API is secure by sending a request using `curl -i $PROXY_IP/echo`:

{% validation unauthorized-check %}
indent: 4
url: /echo
konnect_url: $PROXY_IP
on_prem_url: $PROXY_IP
{% endvalidation %}

    You should see the response:

    ```text
    HTTP/1.1 401 Unauthorized
    Date: Wed, 11 Jan 2044 18:33:46 GMT
    Content-Type: application/json; charset=utf-8
    WWW-Authenticate: Key realm="kong"
    Content-Length: 45
    X-Kong-Response-Latency: 1
    Server: kong/{{site.latest_gateway_oss_version}}

    {
      "message":"No API key found in request"
    }
    ```

## Set up Consumers and keys 

Key authentication in {{site.base_gateway}} works by using the Consumer entity. Keys are assigned to Consumers, and client applications present the key within the requests they make.

Keys are stored as Kubernetes `Secrets` and Consumers are managed with the `KongConsumer` CRD.

1. Create a new `Secret` labeled to use `key-auth` credential type:

    ```bash
    echo '
    apiVersion: v1
    kind: Secret
    metadata:
       name: alex-key-auth
       namespace: kong
       labels:
          konghq.com/credential: key-auth
    stringData:
       key: hello_world
    ' | kubectl apply -f -
    ```

1. Create a new Consumer and attach the credential:

{% entity_example %}
indent: 4
type: consumer
data:
  username: alex
  credentials:
    - alex-key-auth
{% endentity_example %}

1. Make a request to the API and provide your `apikey`:

{% validation request-check %}
indent: 4
url: /echo
headers:
  - 'apikey:hello_world'
status_code: 200
konnect_url: $PROXY_IP
on_prem_url: $PROXY_IP
{% endvalidation %}

    The results should look like this:

    ```
    Welcome, you are connected to node orbstack.
    Running on Pod echo-965f7cf84-mvf6g.
    In namespace default.
    With IP address 192.168.194.10.
    ```

## Next Steps

Congratulations! By making it this far you've deployed {{ site.kic_product_name }}, configured a Service and Route, added rate limiting, proxy caching, and API authentication, all using your normal Kubernetes workflow.

You can learn more about the available plugins (including Kubernetes configuration instructions) on the [Plugin Hub](/plugins/). For more information about {{ site.kic_product_name }} and how it works, see the [how {{ site.kic_product_name }} works](/index/kubernetes-ingress-controller/#how-kic-works) section.