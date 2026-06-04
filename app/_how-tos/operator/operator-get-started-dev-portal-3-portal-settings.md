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
  
min_version:
  operator: '2.2'

works_on:
  - konnect

prereqs:
  skip_product: true
  inline:
    - title: Custom domain
      include_content: prereqs/dev-portal-custom-domain
      icon_url: /assets/icons/konnect.svg

tldr:
  q: How do I configure supporting Dev Portal settings with {{site.operator_product_name}}?
  a: Create a `PortalEmailConfig`, `PortalTeam`, and `PortalCustomDomain` that reference your `Portal`.

related_resources:
  - text: Custom domains
    url: /dev-portal/custom-domains/
  - text: "{{ site.dev_portal }} developer RBAC"
    url: /dev-portal/developer-rbac/
  - text: Global {{ site.dev_portal }} configuration
    url: /dev-portal/portal-settings/
---

## Create a `PortalTeam`

`PortalTeam` creates a developer team and controls whether that team can own applications. For more background, see [{{ site.dev_portal }} RBAC](/dev-portal/developer-rbac/).

1. Create the `PortalTeam` resource:

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

1. Wait for the resource to be ready:

   ```bash
   kubectl wait portalteam/operator-dev-portal-team -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create a `PortalCustomDomain`

`PortalCustomDomain` attaches a public hostname to the portal.

1. Create the `PortalCustomDomain` resource:

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

1. Create a CNAME record in your DNS configuration that points to the automatically generated {{ site.dev_portal }} URL/. For more information, see [Custom domains](/dev-portal/custom-domains/#configure-dns).

1. Wait for the resource to be ready. This resource becomes `Programmed` only after HTTP domain ownership verification completes. Once the hostname is publicly reachable, run the following command:

   ```bash
   kubectl wait portalcustomdomain/operator-dev-portal-domain -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create a `PortalEmailConfig`

`PortalEmailConfig` configures the sender information used by the portal.

1. Create the `PortalEmailConfig` resource:

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

1. Wait for the resource to be ready:

   ```bash
   kubectl wait portalemailconfig/operator-dev-portal-email -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```
