---
title: Create Konnect API Authentication
description: Create the Konnect API authentication resources needed for Kong Event Gateway.
content_type: how_to
permalink: /operator/get-started/event-gateway/authentication/

series:
  id: operator-get-started-event-gateway
  position: 2

breadcrumbs:
  - /operator/
  - index: operator
    group: Gateway Deployment
  - index: operator
    group: Gateway Deployment
    section: Get Started

products:
  - operator

works_on:
  - konnect

prereqs:
  show_works_on: true
  skip_product: true

tldr:
  q: How do I authenticate {{site.operator_product_name}} to {{site.konnect_short_name}} for Kong Event Gateway?
  a: Create a Konnect personal access token or system account token, store it in a Kubernetes `Secret`, and reference it from a `KonnectAPIAuthConfiguration`.
---

## Create a Konnect API token

Create a token in {{site.konnect_short_name}} before continuing:

- For a personal access token, go to [Personal access tokens](https://cloud.konghq.com/global/account/tokens)
- For a system account token, create a system account in {{site.konnect_short_name}} and generate an access token for it

Export the token in your shell:

```bash
export KONNECT_TOKEN='YOUR_KONNECT_TOKEN'
```

Export the Konnect API URL for your region:

```bash
export KONNECT_SERVER_URL='us.api.konghq.com'
```

If your account is not in the US region, replace it with the correct regional API hostname.

## Create a Secret for the token

Create a Kubernetes `Secret` in the `kong` namespace:

```bash
echo '
apiVersion: v1
kind: Secret
metadata:
  name: konnect-api-auth-secret
  namespace: kong
  labels:
    konghq.com/credential: konnect
    konghq.com/secret: "true"
type: Opaque
stringData:
  token: "'"$KONNECT_TOKEN"'"
' | kubectl apply -f -
```

## Create a `KonnectAPIAuthConfiguration`

Create a `KonnectAPIAuthConfiguration` that references the Secret:

```bash
echo '
apiVersion: konnect.konghq.com/v1alpha1
kind: KonnectAPIAuthConfiguration
metadata:
  name: konnect-api-auth
  namespace: kong
spec:
  type: secretRef
  secretRef:
    name: konnect-api-auth-secret
  serverURL: '"$KONNECT_SERVER_URL"'
' | kubectl apply -f -
```

## Validation

Verify that the configuration becomes valid:

```bash
kubectl get konnectapiauthconfiguration konnect-api-auth -n kong
```

The resource should report `VALID=True`.

You can also inspect the condition directly:

```bash
kubectl get konnectapiauthconfiguration konnect-api-auth -n kong \
  -o jsonpath="{.status.conditions[?(@.type=='APIAuthValid')]}"
```

Once authentication is valid, continue to [Deploy Kong Event Gateway with port mapping](/operator/get-started/event-gateway/port-mapping/).
