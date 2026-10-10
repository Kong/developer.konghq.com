---
title: "Migrating from {{ site.kic_product_name }} to {{ site.operator_product_name }}"
description: "Choose an Ingress or Gateway API migration guide while preserving your existing client address."
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
works_on:
  - on-prem
  - konnect
tags:
  - migration
related_resources:
  - text: "Migrate an Ingress configuration"
    url: /operator/migrate/migrate-kic-to-ko-ingress/
  - text: "Migrate a Gateway API configuration"
    url: /operator/migrate/migrate-kic-to-ko-gateway-api/
  - text: "Version compatibility"
    url: /operator/reference/version-compatibility/
  - text: "GatewayConfiguration reference"
    url: /operator/reference/custom-resources/#gatewayconfiguration
---

Migrate from {{ site.kic_product_name }} ({{ site.kic_product_name_short }}) to {{ site.operator_product_name }} ({{ site.operator_product_name_short }}) while keeping the Service and address your clients already use.

## Choose your guide

Choose based on the resources that define your application routes. Each guide contains the complete migration procedure.

| Your routing configuration | Guide |
|---|---|
| Kubernetes `Ingress` resources | [Migrate an Ingress configuration](/operator/migrate/migrate-kic-to-ko-ingress/) |
| Gateway API `HTTPRoute` resources | [Migrate a Gateway API configuration](/operator/migrate/migrate-kic-to-ko-gateway-api/) |

Using Ingress resources does not require converting them to Gateway API routes. {{ site.operator_product_name_short }} uses a `Gateway` resource to manage the new deployment in both procedures.

## How the migration works

1. **Prepare:** Preserve the existing proxy Service and install {{ site.operator_product_name_short }} alongside {{ site.kic_product_name_short }}.
2. **Validate:** Create the replacement gateway and test it while the existing gateway continues serving clients.
3. **Switch traffic:** Change the existing Service's selector to point at the replacement pods. Keep the old installation available for rollback.
4. **Retire:** Wait for existing connections to drain, then remove the old installation.

After migration, {{ site.operator_product_name_short }} manages the replacement gateway and you manage the retained Service. The client address stays on that Service. The operator also creates an internal Service, whose address is published in resource status.

These guides cover DB-less installations deployed with the `kong/kong` or `kong/ingress` Helm chart. The examples use HTTP on port 80; adapt listeners and validation requests to your configuration.

## If you use both APIs

Follow the [Gateway API guide](/operator/migrate/migrate-kic-to-ko-gateway-api/) and include the Ingress settings from [Create the replacement gateway](/operator/migrate/migrate-kic-to-ko-ingress/#create-the-replacement-gateway) in the same `GatewayConfiguration`: set `ingressClass` and combine the controller lists without duplicating entries. Create one replacement gateway, rather than applying the two manifests over each other.

Validate both your Ingress routes and Gateway API routes before switching the Service. Complete the Gateway API route cleanup and check the IngressClass considerations in the [Ingress cleanup step](/operator/migrate/migrate-kic-to-ko-ingress/#retire-the-old-installation) before uninstalling the old release.
