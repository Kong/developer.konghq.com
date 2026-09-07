---
title: Controlling the display order of spec items in the Developer Portal
content_type: support
description: Set an `operationsSorter` (for example `alpha`) in the Developer Portal's spec-renderer layout to control the order spec items are displayed in.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Can the order of spec items be changed in the Developer Portal?
  a: |
    Yes — set an `operationsSorter` (for example `alpha`) in the spec-renderer layout's `swaggerUIOptions`. Note the sidebar doesn't follow this custom order, so disable it (`hasSidebar: false`) when using an `operationsSorter`. On Kong Gateway (Enterprise) 3.11.0.0 and later, this workflow requires a license with the `portal_and_vitals_key` extra, since it depends on the Portal's file-management Admin API.
related_resources:
  - text: Swagger UI configuration options (`operationsSorter`)
    url: https://github.com/swagger-api/swagger-ui/blob/master/docs/usage/configuration.md
  - text: "`kong-portal-templates`"
    url: https://github.com/Kong/kong-portal-templates
---

## Problem

When importing an OpenAPI spec file into the Developer Portal, items are displayed in a different order than expected, even though loading the same spec into a Swagger Editor instance shows everything in the expected order.

## Solution

The order can be changed by using an `operationsSorter` configuration. This can be set from the spec-renderer layout. Please note that the sidebar does not follow this order, so we would recommend disabling the sidebar if using an `operationsSorter`.

For example to sort alphabetically, modify `workspaces/<workspace-name>/themes/<theme-name>/layouts/system/spec-renderer.html` in the `kong-portal-templates` repository (for example, `workspaces/default/themes/base/layouts/system/spec-renderer.html`) and change `swaggerUIOptions` to be as below (note, the sidebar is set to false too in the below example);

Note: on Kong Gateway (Enterprise) 3.11.0.0 and later, the on-prem/Gateway-native Developer Portal is hard-deprecated and gated behind a separate, support-provided `portal_and_vitals_key` license extra — without it, the Portal's file-management Admin API that this custom-template workflow relies on to push the edited template returns a flat 404 regardless of workspace configuration. Confirm with Kong Support that your license includes this key before relying on this workflow.

```javascript

window.onload = function () {
      var swaggerUIOptions = {
        dom_id: '#ui-wrapper', // Determine what element to load swagger ui
        docExpansion: 'list',
        deepLinking: true, // Enables dynamic deep linking for tags and operations
        filter: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIBundle.SwaggerUIStandalonePreset
        ],
        plugins: [
          SwaggerUIKongTheme.SwaggerUIKongTheme,
          SwaggerUIBundle.plugins.DownloadUrl
        ],
        layout: 'KongLayout',
        theme: {
          hasSidebar: false,
          swaggerAbsoluteTop: "90px"
        },
        operationsSorter: 'alpha'
      }
```
