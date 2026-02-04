---
# @TODO KO 2.1
title: Manage Consumers and Credentials
description: "Learn how to create Kong Consumers and manage credentials for authentication with the Kong Gateway Operator."
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
  q: How do I manage authentication credentials for my clients?
  a: Create a `KongConsumer` resource and link it to a Kubernetes `Secret` containing the credentials.
---

## Overview

In {{ site.base_gateway }}, a **Consumer** represents a user or a service that consumes an API. Consumers allows you to:
- Issue credentials (like API keys) to specific users.
- Group users for authorization (ACLs).
- Rate limit specific users or tiers.

This guide shows how to create a `KongConsumer`, provision an API key, and secure an `HTTPRoute` using the Key Authentication plugin.

## Prerequisites

- Access to a Kubernetes cluster with {{ site.operator_product_name }} installed.
- A functional `Gateway` and `HTTPRoute`.

## 1. Configure the Key Authentication Plugin

First, create a `KongPlugin` resource to enable key authentication. This plugin will enforce that requests must include a valid API key.

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

## 2. Attach the Plugin to an HTTPRoute

Apply the plugin to your `HTTPRoute` using an `ExtensionRef` filter. This ensures that any traffic matching the route requires authentication.

```yaml
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
          port: 1027
```

## 3. Create a Consumer

Create a `KongConsumer` resource to represent the user.

### Standard / Standalone

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

### Konnect / Hybrid

If you are using Konnect, you must refer to the Control Plane using `controlPlaneRef`.

```yaml
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
      name: <your-control-plane-name>
credentials:
- test-user-apikey
```

{% tip %}
NOTE: To guarantee a consistent name for the ```konnectNamespacedRef```, use [Static naming for Konnect Control Planes](/operator/konnect/how-to-static-naming)
{% endtip %}

## 4. Provision a Credential

Create a Kubernetes `Secret` to store the API key. You must label the secret with `konghq.com/credential: key-auth` so the Operator knows to associate it with the consumer.

{% tip %}
For more information on how the Operator handles secrets, please refer to [Secrets and Credentials Reference](/operator/reference/secrets-and-credentials)
{% endtip %}


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

## Verify Access

1.  **Unauthorized Request**: Try to access the route without a key. You should receive a `401 Unauthorized` response.

    ```bash
    curl -i http://$GATEWAY_IP/echo
    ```

2.  **Authorized Request**: Access the route with the API key in the `apikey` header.

    ```bash
    curl -i -H "apikey: secret-api-key" http://$GATEWAY_IP/echo
    ```

    You should receive a `200 OK` response from the echo service.
