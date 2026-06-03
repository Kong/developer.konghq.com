---
title: Configure portal sign-in with OIDC
description: Configure a `PortalIdentityProviderRequest` for Dev Portal sign-in with {{site.operator_product_name}}.
content_type: how_to
permalink: /operator/get-started/dev-portal/identity-provider/

series:
  id: operator-get-started-dev-portal
  position: 4

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
  operator:
    konnect:
      auth: true

tldr:
  q: How do I configure Dev Portal sign-in with {{site.operator_product_name}}?
  a: Create a `PortalIdentityProviderRequest` that references your `Portal` and supplies your OIDC issuer, client ID, and client secret.
---

Export your OIDC settings:

```bash
export OIDC_ISSUER_URL='https://accounts.google.com'
export OIDC_CLIENT_ID='your-client-id'
export OIDC_CLIENT_SECRET='your-client-secret'
```

## Create the `PortalIdentityProviderRequest`

```bash
echo '
apiVersion: konnect.konghq.com/v1alpha1
kind: PortalIdentityProviderRequest
metadata:
  name: operator-dev-portal-oidc
  namespace: kong
spec:
  portalRef:
    type: namespacedRef
    namespacedRef:
      name: operator-dev-portal
  apiSpec:
    type: oidc
    config:
      type: oIDC
      oIDC:
        clientID: '"$OIDC_CLIENT_ID"'
        clientSecret: '"$OIDC_CLIENT_SECRET"'
        issuerURL: '"$OIDC_ISSUER_URL"'
        scopes:
          - openid
          - profile
          - email
' | kubectl apply -f -
```

## Validation

```bash
kubectl wait portalidentityproviderrequest/operator-dev-portal-oidc -n kong \
  --for=condition=Programmed=True \
  --timeout=10m
```
