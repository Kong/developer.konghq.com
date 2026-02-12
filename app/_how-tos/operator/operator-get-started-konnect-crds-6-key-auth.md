---
title: Enable Key Authentication
description: Secure an API using the `key-auth` plugin and credentials from a `KongConsumer`.
content_type: how_to
permalink: /operator/get-started/konnect-crds/key-authentication/
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

series:
  id: operator-get-started-konnect-crds
  position: 6 

tldr:
  q: How do I secure an API with key authentication using {{site.konnect_short_name}} CRDs?
  a: |
    Apply the `key-auth` plugin to a route and attach credentials using the `KongConsumer` and `KongCredentialAPIKey` CRDs.

products:
  - operator

tools:
  - operator

works_on:
  - konnect

next_steps:
  - text: See the Custom resource definitions (CRDs) reference
    url: /operator/reference/custom-resources/
---


## Add authentication to the httpbin service

1. Create a new `key-auth` plugin.

{% entity_example %}
type: plugin
indent: 4
data:
  name: key-auth
  
  kongservice: service
  other_plugins: rate-limit-5-min,proxy-cache-all-endpoints
{% endentity_example %}

1. Test that the API is secure by sending a request using `curl -i $PROXY_IP/anything`:

{% validation unauthorized-check %}
indent: 4
url: /anything
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
         konghq.com/secret: "true"
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
  spec:
   controlPlaneRef:
     type: konnectNamespacedRef
     konnectNamespacedRef:
       name: gateway-control-plane
{% endentity_example %}

1. Make a request to the API and provide your `apikey`:

{% validation request-check %}
indent: 4
url: /anything
headers:
  - 'apikey:hello_world'
status_code: 200
konnect_url: $PROXY_IP
on_prem_url: $PROXY_IP
{% endvalidation %}

The request should be successful.