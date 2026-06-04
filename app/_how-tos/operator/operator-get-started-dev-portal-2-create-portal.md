---
title: Create a {{ site.dev_portal }} and publish content
description: Create a `Portal`, a `PortalPage`, and a `PortalCustomization` with {{site.operator_product_name}}.
content_type: how_to
permalink: /operator/get-started/dev-portal/create-portal/

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
  operator:
    konnect:
      auth: true

tldr:
  q: How do I create a {{site.dev_portal}} with {{site.operator_product_name}}?
  a: Create a `Portal`, attach a published `PortalPage`, and apply a `PortalCustomization`.
---

## Create the `Portal`

The `Portal` represents the {{ site.dev_portal }} itself in {{site.konnect_short_name}} and provides the parent object for pages, customizations, teams, and sign-in settings. For more information, see the [{{ site.dev_portal }} overview](/dev-portal/).

1. Create the `Portal` resource:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: Portal
   metadata:
     name: operator-dev-portal
     namespace: kong
   spec:
     konnect:
       authRef:
         name: konnect-api-auth
     apiSpec:
       name: operator-dev-portal
       displayName: Operator Dev Portal
       description: Developer portal managed by Kong Operator
       authenticationEnabled: Enabled
       defaultPageVisibility: public
       defaultAPIVisibility: private
   ' | kubectl apply -f -
   ```

1. Wait for the resource to be ready:

   ```bash
   kubectl wait portal/operator-dev-portal -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create a `PortalPage`

The `PortalPage` adds published content to the portal. For more information, see [{{ site.dev_portal }} pages and content](/dev-portal/pages-and-content/).

1. Create the `PortalPage` resource:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: PortalPage
   metadata:
     name: operator-dev-portal-getting-started
     namespace: kong
   spec:
     portalRef:
       type: namespacedRef
       namespacedRef:
         name: operator-dev-portal
     apiSpec:
       title: Getting Started
       slug: getting-started
       description: Landing page for the developer portal
       content: |
         # Getting Started

         Welcome to the developer portal managed by Kong Operator.
       status: published
       visibility: public
   ' | kubectl apply -f -
   ```

1. Wait for the resource to be ready:

   ```bash
   kubectl wait portalpage/operator-dev-portal-getting-started -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```

## Create a `PortalCustomization`

The `PortalCustomization` lets you change the portal's layout, navigation, and branding. For more information, see [{{ site.dev_portal }} customizations](/dev-portal/customizations/dev-portal-customizations/).

1. Create the `PortalCustomization` resource:

   ```bash
   echo '
   apiVersion: konnect.konghq.com/v1alpha1
   kind: PortalCustomization
   metadata:
     name: operator-dev-portal-customization
     namespace: kong
   spec:
     portalRef:
       type: namespacedRef
       namespacedRef:
         name: operator-dev-portal
     apiSpec:
       css: |
         body { background-color: #f6f7fb; }
   ' | kubectl apply -f -
   ```

1. Wait for the resource to be ready:

   ```bash
   kubectl wait portalcustomization/operator-dev-portal-customization -n kong \
     --for=condition=Programmed=True \
     --timeout=10m
   ```
