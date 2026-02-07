---
title: Manage Consumers and credentials with {{site.operator_product_name}}
description: "Learn how to create Consumers and manage credentials for authentication with {{site.operator_product_name}}."
content_type: how_to
permalink: /operator/dataplanes/how-to/manage-consumers/
breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: "How-To"
products:
  - operator
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I manage authentication credentials for my Consumers?
  a: Create a `KongConsumer` resource and link it to a Kubernetes `Secret` containing the credentials.

prereqs:
  operator:
    konnect:
      auth: true
      control_plane: true
  inline:
    - title: Create Gateway resources
      include_content: /prereqs/operator/gateway

related_resources:
  - text: Consumer entity
    url: /gateway/entities/consumer/
  - text: Key Authentication plugin
    url: /plugins/key-auth/
---

## Create the echo Service

Run the following command to create a sample echo Service:
```bash
kubectl apply -f https://developer.konghq.com/manifests/kic/echo-service.yaml -n kong
```

## Configure the Key Authentication plugin

First, create a `KongPlugin` resource to enable [key authentication](/plugins/key-auth/):

```bash
echo '
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: key-auth
  namespace: kong
plugin: key-auth
config:
  key_names:
  - apikey
' | kubectl apply -f -
```

## Create the HTTPRoute

Create an `HTTPRoute` resource and add the plugin using an `ExtensionRef` filter:

```sh
echo '
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo
  namespace: kong
spec:
  parentRefs:
    - name: kong
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /echo
      filters:
        - type: ExtensionRef
          extensionRef:
            group: configuration.konghq.com
            kind: KongPlugin
            name: key-auth
      backendRefs:
        - name: echo
          port: 1027' | kubectl apply -f -
```

## Create a Secret

Create a Kubernetes `Secret` to store the API key and label the secret with `konghq.com/credential: key-auth`:

```bash
echo '
apiVersion: v1
kind: Secret
metadata:
  name: test-user-apikey
  namespace: kong
  labels:
    konghq.com/credential: key-auth
    konghq.com/secret: "true"
stringData:
  key: secret-api-key
' | kubectl apply -f -
```

For more information on how {{site.operator_product_name}} handles Secrets, please refer to the [Secrets reference](/operator/reference/secrets)

## Create a Consumer

Create a `KongConsumer` resource to represent the user, and reference the `test-user-apikey` Secret we created:

```bash
echo '
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: test-user
  namespace: kong
  annotations:
    kubernetes.io/ingress.class: kong
username: test-user
credentials:
- test-user-apikey
' | kubectl apply -f -
```
{: data-deployment-topology="on-prem" }

```bash
echo '
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: test-user
  namespace: kong
  annotations:
    kubernetes.io/ingress.class: kong
username: test-user
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: gateway-control-plane
credentials:
- test-user-apikey
' | kubectl apply -f -
```
{: data-deployment-topology="konnect" }

{:.info}
> To guarantee a consistent name for the `konnectNamespacedRef`, use [static naming](/operator/konnect/how-to/static-naming/)
{: data-deployment-topology="konnect" }


## Validate

1. Get the Gateway's external IP:
   
   ```bash
   export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath='{.status.addresses[0].value}')
   ```

1. Try to access the Route without a key:

   ```bash
   curl -i http://$PROXY_IP/echo
   ```

   You should receive a `401 Unauthorized` response.

2. Access the route with the API key in the `apikey` header:

   ```bash
   curl -i -H "apikey: secret-api-key" http://$PROXY_IP/echo
   ```

   You should receive a `200 OK` response from the echo service.
