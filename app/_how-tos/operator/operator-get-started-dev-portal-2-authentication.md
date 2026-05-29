---
title: Create API Authentication
description: Create the Konnect API authentication resources needed for Dev Portal CRDs.
content_type: how_to
permalink: /operator/get-started/dev-portal/authentication/

series:
  id: operator-get-started-dev-portal
  position: 2

breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Get Started

products:
  - operator

works_on:
  - konnect

prereqs:
  show_works_on: true
  skip_product: true

tldr:
  q: How do I authenticate {{site.operator_product_name}} to {{site.konnect_short_name}} for Dev Portal CRDs?
  a: Create a Konnect personal access token or system account token, store it in a Kubernetes `Secret`, and reference it from a `KonnectAPIAuthConfiguration`.
---

## Create a Konnect API token

Create a token in {{site.konnect_short_name}} before continuing:

- For a personal access token, go to [Personal access tokens](https://cloud.konghq.com/global/account/tokens)
- For a system account token, create a system account in {{site.konnect_short_name}} and generate an access token for it

Export the token:

```bash
export KONNECT_TOKEN='kpat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
```

## Create the Secret

```bash
echo 'apiVersion: v1
kind: Secret
metadata:
  name: konnect-api-auth-secret
  namespace: kong
  labels:
    konghq.com/credential: konnect
    konghq.com/secret: "true"
stringData:
  token: "'$KONNECT_TOKEN'"' | kubectl apply -f -
```

## Create the `KonnectAPIAuthConfiguration`

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
  serverURL: us.api.konghq.com
' | kubectl apply -f -
```

## Validation

```bash
kubectl get konnectapiauthconfiguration konnect-api-auth -n kong
```

You should see `VALID=True`.

Once the auth configuration is valid, continue to [Create a Dev Portal](/operator/get-started/dev-portal/create-portal/).
