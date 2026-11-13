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

Migrate from {{ site.kic_product_name }} ({{ site.kic_product_name_short }}) to {{ site.operator_product_name }} ({{ site.operator_product_name_short }}) while you keep the Service and address your clients already use.

## Choose your migration guide

Choose a guide based on the resources that define your application routes.
Each guide contains the complete migration procedure.

{% table %}
columns:
  - title: Your routing configuration
    key: config
  - title: Guide
    key: guide
rows:
  - config: Kubernetes `Ingress` resources
    guide: "[Migrate an Ingress configuration](/operator/migrate/migrate-kic-to-ko-ingress/)"
  - config: Gateway API route resources, such as `HTTPRoute` or `GRPCRoute`
    guide: "[Migrate a Gateway API configuration](/operator/migrate/migrate-kic-to-ko-gateway-api/)"
{% endtable %}

If you use Ingress resources, you don't need to convert them to Gateway API routes.
In both procedures, {{ site.operator_product_name_short }} uses a `Gateway` resource to manage the new deployment.

## How the migration works

The migration from {{ site.kic_product_name_short }} to {{ site.operator_product_name_short }} has four stages:

1. **Prepare:** Preserve the existing proxy Service, and install {{ site.operator_product_name_short }} alongside {{ site.kic_product_name_short }}.
2. **Validate:** Create the replacement gateway, and test it while the existing gateway continues to serve clients.
3. **Switch traffic:** Change the selector of the existing Service to point at the replacement pods. Keep the old installation available for rollback.
4. **Retire:** Wait for existing connections to drain, then remove the old installation.

After the migration, {{ site.operator_product_name_short }} manages the replacement gateway, and you manage the retained Service.
The client address stays on the retained Service.
{{ site.operator_product_name_short }} also creates an internal Service, and publishes the address of that internal Service in resource status.

The migration guides cover DB-less installations deployed with the `kong/kong` or `kong/ingress` Helm chart.
The examples use HTTP on port 80.
Adapt the listeners and validation requests to your configuration.

## If you use both APIs

If you use both Ingress and Gateway API resources, follow the [Gateway API guide](/operator/migrate/migrate-kic-to-ko-gateway-api/).
In the same `GatewayConfiguration`, include the Ingress settings from [Create the replacement gateway](/operator/migrate/migrate-kic-to-ko-ingress/#create-the-replacement-gateway):

* Set `ingressClass`.
* Combine the two controller lists, without duplicate entries.

Create one replacement gateway.
Don't apply the two manifests on top of each other.

Before you switch the Service, validate both your Ingress routes and your Gateway API routes.
Before you uninstall the old release, complete the Gateway API route cleanup, and check the `IngressClass` considerations in the [Ingress cleanup step](/operator/migrate/migrate-kic-to-ko-ingress/#retire-the-old-installation).
