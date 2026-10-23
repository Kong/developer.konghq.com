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

cleanup:
  inline:
    - title: Delete the Konnect resources
      content: |
        Deleting the `KonnectGatewayControlPlane` also deletes the control plane the {{site.operator_product_name}} created in {{ site.konnect_short_name }}:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          kongconsumer/alex \
          kongplugin/key-auth \
          kongplugin/proxy-cache-all-endpoints \
          kongroute/route \
          kongservice/service \
          dataplane/dataplane \
          konnectextension/my-konnect-config \
          konnectgatewaycontrolplane/gateway-control-plane \
          secret/alex-key-auth \
          secret/konnect-api-auth-secret \
          konnectapiauthconfiguration/konnect-api-auth
        ```
        {: data-test-cleanup="block" }
      icon_url: /assets/icons/kubernetes.svg

    - title: Delete the namespaces
      content: |
        ```bash
        helm uninstall kong-operator -n kong-system
        kubectl delete namespace kong kong-system
        ```
      icon_url: /assets/icons/kubernetes.svg
---


## Add authentication to the httpbin service

1. Create a new `key-auth` plugin:

   <!-- vale off -->
{% konnect_crd %}
kind: KongPlugin
apiVersion: configuration.konghq.com/v1
metadata:
  name: key-auth
plugin: key-auth
{% endkonnect_crd %}
   <!-- vale on -->

1. Apply the plugin by annotating the `KongService` with the names of the plugins you have created:

   ```bash
   kubectl annotate -n kong kongservice service konghq.com/plugins=proxy-cache-all-endpoints,key-auth --overwrite
   ```
   {: data-test-step="block" }

1. Test that the API is secure by sending a request using `curl -i $PROXY_IP/echo`:

   <!-- vale off -->
{% validation unauthorized-check %}
url: /echo
message: No API key found in request
konnect_url: http://$PROXY_IP
on_prem_url: http://$PROXY_IP
indent: 3
{% endvalidation %}
   <!-- vale on -->

   You should see the response:

   ```text
   HTTP/1.1 401 Unauthorized
   Date: Wed, 11 Jan 2044 18:33:46 GMT
   Content-Type: application/json; charset=utf-8
   WWW-Authenticate: Key realm="kong"
   Content-Length: 45
   X-Kong-Response-Latency: 1
   Server: kong/{{site.data.gateway_latest.ee-version}}-enterprise-edition

   {
     "message":"No API key found in request",
     "request_id":"89e4883a53a0af51b322204ad1zfa16a"
   }
   ```
   {:.no-copy-code}

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
   {: data-test-step="block" }

1. Create a new Consumer and attach the credential:

   <!-- vale off -->
{% konnect_crd %}
kind: KongConsumer
apiVersion: configuration.konghq.com/v1
metadata:
  name: alex
username: alex
credentials:
- alex-key-auth
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
{% endkonnect_crd %}
   <!-- vale on -->

1. Wait for the Consumer and its credential to be reconciled:

   ```bash
   kubectl wait -n kong kongconsumer/alex --for=condition=Programmed=True --timeout=5m
   ```
   {: data-test-step="block" }

1. Make a request to the API and provide your `apikey`:

   <!-- vale off -->
{% validation request-check %}
url: /echo
headers:
  - 'apikey:hello_world'
status_code: 200
konnect_url: http://$PROXY_IP
on_prem_url: http://$PROXY_IP
indent: 3
{% endvalidation %}
   <!-- vale on -->

   The request should be successful.
