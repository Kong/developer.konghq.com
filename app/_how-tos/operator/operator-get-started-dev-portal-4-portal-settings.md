---
title: Configure portal settings
description: Configure email, team access, IP allow lists, and a custom domain for a Dev Portal with {{site.operator_product_name}}.
content_type: how_to
permalink: /operator/get-started/dev-portal/portal-settings/

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
  q: How do I configure supporting Dev Portal settings with {{site.operator_product_name}}?
  a: Create a `PortalEmailConfig`, `PortalTeam`, and `PortalCustomDomain` that reference your `Portal`.
---

Set a hostname for your custom domain before continuing:

```bash
export PORTAL_DOMAIN='portal.example.dev'
```

Use a hostname that you control. The resource can be created before DNS cutover, but the domain name must be valid.

## Create the supporting Portal resources

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
---
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
---
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
    hostname: '"$PORTAL_DOMAIN"'
    ssl:
      type: standard
      standard:
        domainVerificationMethod: http
' | kubectl apply -f -
```

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

Inspect the resources:

```bash
kubectl get portalemailconfig,portalteam,portalcustomdomain -n kong
```

`PortalIPAllowList` is also available as a CRD, but it is not included in this getting started flow because the live Konnect reconciliation path currently returns a `400 unable to parse body` error on update.

Continue to [Configure portal sign-in](/operator/get-started/dev-portal/identity-provider/).
