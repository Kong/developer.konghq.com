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
  
min_version:
  operator: '2.2'

works_on:
  - konnect

prereqs:
  skip_product: true
  inline:
    - title: OIDC provider
      include_content: prereqs/auth/oidc/okta-dev-portal
      icon_url: /assets/icons/okta.svg

cleanup:
  inline:
    - title: Delete the resources created in this guide
      content: |
        Delete the `Portal` resources and the {{ site.konnect_short_name }} authentication configuration:

        ```bash
        kubectl delete -n kong --ignore-not-found \
          portalidentityproviderrequest/operator-dev-portal-oidc \
          portalemailconfig/operator-dev-portal-email \
          portalcustomdomain/operator-dev-portal-domain \
          portalteam/operator-dev-portal-team \
          portalcustomization/operator-dev-portal-customization \
          portalpage/operator-dev-portal-getting-started \
          portal/operator-dev-portal \
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

tldr:
  q: How do I configure Dev Portal sign-in with {{site.operator_product_name}}?
  a: Create a `PortalIdentityProviderRequest` that references your `Portal` and supplies your OIDC issuer, client ID, and client secret.

related_resources:
  - text: "{{ site.dev_portal }} SSO"
    url: /dev-portal/sso/
  - text: Application authentication strategies
    url: /dev-portal/auth-strategies/
  - text: Enable self-managed OIDC auth with Okta in {{ site.dev_portal }}
    url: /how-to/enable-oidc-auth-for-dev-portal/
---

## Create the PortalIdentityProviderRequest

The `PortalIdentityProviderRequest` configures the OIDC sign-in provider for the portal. Once applied, developers who visit the portal can sign in using your identity provider instead of a local account.

Create the `PortalIdentityProviderRequest` resource:

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

Check that the resource is ready:

```bash
kubectl wait portalidentityproviderrequest/operator-dev-portal-oidc -n kong \
  --for=condition=Programmed=True \
  --timeout=10m
```
