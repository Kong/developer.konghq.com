---
title: "Dedicated Cloud Gateway domain breaking changes"
content_type: reference
layout: reference
breadcrumbs:
  - /dedicated-cloud-gateways/
products:
    - gateway

works_on:
    - konnect

tags:
    - upgrade
    - versioning

description: "Review domain breaking changes for Dedicated Cloud Gateways."

related_resources:
  - text: Dedicated Cloud Gateways
    url: /dedicated-cloud-gateways/
  - text: Dedicated Cloud Gateways Custom DNS
    url: /dedicated-cloud-gateways/reference/#custom-dns
  - text: "{{site.konnect_short_name}} release notes"
    url: https://releases.konghq.com/en

faqs:
  - q: Will my current traffic break during the Dedicated Cloud Gateways domain migration?
    a: No. As long as you transition to the new domain before the cut-off date on September 30, 2025, there will be no downtime.
  - q: Do I need to change anything in {{site.konnect_short_name}} for the Dedicated Cloud Gateways domain migration?
    a: No. All changes are DNS or infrastructure-related. The {{site.konnect_short_name}} UI will automatically reflect domain mappings.
  - q: What if I use a custom domain with a Kong-managed certificate?
    a: |
      Contact [Kong Support](https://support.konghq.com). This path is currently unsupported for seamless migration.
---

The Dedicated Cloud Gateways domain structure is changing from `konghq.com` to `konggateway.com`. Kong is making this change to align with {{site.base_gateway}} runtimes. 

Legacy `konghq.com` domains will be deactivated and no longer provisioned on **September 30, 2025**. There will be a transition period starting July 1, 2025 where both the legacy and new domains will be available so you can migrate to the new domain. All existing gateway traffic will continue to work during the transition. There will be no downtime if migration steps are followed correctly.

## Dedicated Cloud Gateway domain migration

Starting July 1, 2025, new `*.konggateway.com` domains will be visible in the {{site.konnect_short_name}} UI. Both legacy `*.konghq.com` and new domains will be live simultaneously. Legacy domains will display a deprecation notice with a cut-off date.

To migrate to the new domain, you must update the following:

<!--vale off-->
{% table %}
columns:
  - title: Setting
    key: setting
  - title: Action
    key: action
rows:
  - setting: "Gateway domains"
    action: "Update gateway domains from `*.gateways.konghq.com` to `*.gateways.konggateway.com`."
  - setting: "Edge domains"
    action: "Update edge domains from `*.edge.gateways.konghq.com` to `*.edge.gateways.konggateway.com`."
  - setting: "Custom domain CNAMEs"
    action: "Update your records to point to the new `*.konggateway.com` target."
  - setting: "ACME challenge records"
    action: "Update `_acme-challenge` DNS records accordingly."
  - setting: "Kong-managed certificates for custom domains"
    action: "Contact [Kong Support](https://support.konghq.com) to migrate."
{% endtable %}
<!--vale on-->