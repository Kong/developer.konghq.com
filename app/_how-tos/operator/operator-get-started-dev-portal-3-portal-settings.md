---
title: Configure portal settings
description: Configure email settings, team access, and a custom domain for a {{ site.dev_portal }} with {{site.operator_product_name}}.
content_type: how_to
permalink: /operator/get-started/dev-portal/portal-settings/

series:
  id: operator-get-started-dev-portal
  position: 3

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
  inline:
    - title: Custom domain
      include_content: prereqs/dev-portal-custom-domain
      icon_url: /assets/icons/konnect.svg

tldr:
  q: How do I configure supporting Dev Portal settings with {{site.operator_product_name}}?
  a: Create a `PortalEmailConfig`, `PortalTeam`, and `PortalCustomDomain` that reference your `Portal`.
---

## Create a `PortalEmailConfig`

`PortalEmailConfig` configures the sender information used by the portal:

```bash
echo '
apiVersion: konnect.konghq.com/v1alpha1
kind: PortalEmailConfig
metadata:
  name: operator-dev-portal-email
  namespace: kong
spec:
  portalRef:
    type: namespacedRef
    namespacedRef:
      name: operator-dev-portal
  apiSpec:
    domainName: '"$PORTAL_EMAIL_DOMAIN"'
    fromEmail: '"$PORTAL_FROM_EMAIL"'
    fromName: Operator Dev Portal
    replyToEmail: '"$PORTAL_REPLY_TO_EMAIL"'
' | kubectl apply -f -
```

## Create a `PortalTeam`

`PortalTeam` creates a developer team and controls whether that team can own applications. For more background, see [{{ site.dev_portal }} RBAC](/dev-portal/developer-rbac/).

```bash
echo '
apiVersion: konnect.konghq.com/v1alpha1
kind: PortalTeam
metadata:
  name: operator-dev-portal-team
  namespace: kong
spec:
  portalRef:
    type: namespacedRef
    namespacedRef:
      name: operator-dev-portal
  apiSpec:
    name: platform-team
    description: Team managed by Kong Operator
    canOwnApplications: Enabled
' | kubectl apply -f -
```

## Create a `PortalCustomDomain`

`PortalCustomDomain` attaches a public hostname to the portal:

```bash
echo '
apiVersion: konnect.konghq.com/v1alpha1
kind: PortalCustomDomain
metadata:
  name: operator-dev-portal-domain
  namespace: kong
spec:
  portalRef:
    type: namespacedRef
    namespacedRef:
      name: operator-dev-portal
  apiSpec:
    enabled: Enabled
    hostname: '"$PORTAL_HOSTNAME"'
    ssl:
      type: standard
      standard:
        domainVerificationMethod: http
' | kubectl apply -f -
```

## Validation

`PortalTeam` has no external verification dependency and becomes `Programmed` immediately:

```bash
kubectl wait portalteam/operator-dev-portal-team -n kong \
  --for=condition=Programmed=True \
  --timeout=10m
```

`PortalEmailConfig` and `PortalCustomDomain` become `Programmed` only after their domain verification completes. Once the DNS records are in place and the hostname is reachable, check their status with:

```bash
kubectl get portalemailconfig/operator-dev-portal-email \
  portalcustomdomain/operator-dev-portal-domain \
  -n kong
```
