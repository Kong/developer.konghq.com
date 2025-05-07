---
title: "{{site.konnect_short_name}} Account, Pricing, and Organization Deactivation"

description: Learn how to cancel and deactivate an account in {{site.konnect_short_name}}
breadcrumbs:
  - /konnect-platform/
content_type: policy
layout: reference

products:
  - gateway
works_on:
    - konnect

related_resources:
  - text: "{{site.base_gateway}} version support policy"
    url: /gateway/version-support-policy/
  - text: Common Vulnerability Scoring System
    url: https://www.first.org/cvss/
faqs:
  - q: How do I close my Plus or Enterprise account?
    a: |
      To close a Plus or Enterprise account, you can:
      * Go to [**My Account**](https://cloud.konghq.com/global/account) > **Delete Account**.
      * Go to Organization > Settings > General > **Deactivate Organization**
      * Request deactivation from [Kong Support](https://support.konghq.com/).
  - q: When is my free account deactivated?
    a: |
      A free {{site.konnect_short_name}} organization is automatically deactivated after 30
      days of inactivity.

      Your organization is considered inactive when:
      * There is no user login into the organization within the last 30 days.
      * There are no API requests in either the current or the previous billing cycle
      (30 day increments).
  - q: What happens if an organization is deactivated?
    a: |
      If your organization account is deactivated, and can no longer log into the
      organization, either through the {{site.konnect_short_name}} UI or the API, then the following happens:
      * All billing stops immediately, and all {{site.konnect_short_name}} subscriptions
      are removed.
      * The control plane (both the {{site.base_gateway}} and {{site.product_mesh_name}} global control planes) associated with the organization are decommissioned.
      * {{site.product_mesh_name}} local zone control planes and data plane nodes (workloads) continue to run, but will not receive new configuration updates.
      * Any users that were part of the organization are removed from any teams
      associated with the organization, and lose roles associated with the deactivated organization.
      Their accounts are otherwise unaffected.
      * The email associated with the organization is locked and can't be used to
      create another {{site.konnect_short_name}} account.

      If you have registered data plane nodes, they won't be
      stopped by {{site.konnect_short_name}}. They will no longer proxy data, but the
      nodes will keep running until manually stop them.
  - q: How do I deactivate or reactivate an org?
    a: |
      Contact [Kong Support](https://support.konghq.com/) to do any of the following:
      * Deactivate an organization that you registered
      * Reactivate an organization that has been deactivated
      * Unlock an email for use with another organization
  - q: How do I manage and view billing and usage?
    a: |
      You can view service, Dev Portal, and API call usage from the [Billing and Usage](https://cloud.konghq.com/settings/billing-settings).
---

{{site.konnect_short_name}} offers [two plans](https://konghq.com/pricing).

* **{{site.konnect_short_name}} Plus**: {{site.konnect_short_name}} Plus is the simplest way to get started with {{site.konnect_short_name}}, allowing you to only pay for the services you consume. New accounts are automatically given a month of free credits as part of 30-day trial. You can claim your Konnect Plus credits by [signing up](https://konghq.com/products/kong-konnect/register).
* **{{site.konnect_short_name}} Enterprise**: {{site.konnect_short_name}} Enterprise is our contract-based option that includes 24x7x365 support and professional services access to help you build and maintain your own custom environment. Learn more about enterprise on our [pricing page](https://konghq.com/pricing)


## License management

When you create a {{site.konnect_short_name}} account, {{site.ee_product_name}}, {{site.kic_product_name}} (KIC), and {{site.mesh_product_name}}
licenses are automatically provisioned to the organization. You do not need to manage these
licenses manually.

Any data plane nodes or {{site.kic_product_name}} associations configured through the [Gateway Manager](/gateway-manager/)
also implicitly receive the same license from the {{site.konnect_short_name}}
control plane. You should never have to deal with a license directly.

For any license questions, contact your sales representative.

## Geographic region management

When you create a {{site.konnect_short_name}} account, you select a [geographic region](/konnect/geos/) for your instance. Geos are distinct deployments of {{site.konnect_short_name}} with objects, such as services and consumers, that are geo-specific. Only authentication is shared between {{site.konnect_short_name}} geos.
