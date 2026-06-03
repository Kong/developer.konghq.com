---
title: Configure portal settings
description: Configure email, team access, IP allow lists, and a custom domain for a Dev Portal with {{site.operator_product_name}}.
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
  operator:
    konnect:
      auth: true

tldr:
  q: How do I configure supporting Dev Portal settings with {{site.operator_product_name}}?
  a: Create a `PortalEmailConfig`, `PortalTeam`, and `PortalCustomDomain` that reference your `Portal`.
---

## Create a `PortalEmailConfig`

`PortalEmailConfig` configures the sender information used by the portal.

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
    domainName: example.com
    fromEmail: noreply@example.com
    fromName: Operator Dev Portal
    replyToEmail: support@example.com
' | kubectl apply -f -
```

## Create a `PortalTeam`

`PortalTeam` creates a developer team and controls whether that team can own applications. For more background, see [Dev Portal RBAC](/dev-portal/developer-rbac/).

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

`PortalCustomDomain` attaches a public hostname to the portal. For more background, see [Dev Portal custom domains](/dev-portal/custom-domains/) and the broader [Dev Portal docs](/dev-portal/).

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
    hostname: portal.example.dev
    ssl:
      type: standard
      standard:
        domainVerificationMethod: http
' | kubectl apply -f -
```

Use a hostname that you control. The resource can be created before DNS cutover, but the domain name must be valid.

## Validation

Wait for the resources to be programmed:

```bash
kubectl wait portalemailconfig/operator-dev-portal-email -n kong \
  --for=condition=Programmed=True \
  --timeout=10m

kubectl wait portalteam/operator-dev-portal-team -n kong \
  --for=condition=Programmed=True \
  --timeout=10m

kubectl wait portalcustomdomain/operator-dev-portal-domain -n kong \
  --for=condition=Programmed=True \
  --timeout=10m
```
