---
title: Install {{site.base_gateway}}
subtitle: "{{site.base_gateway}} is a low-demand, high-performing API gateway. You can set up {{site.base_gateway}} with Konnect, or install it on various self-managed systems."

description: "Install {{site.base_gateway}} on your preferred platform."

products:
    - gateway

content_type: reference
layout: install

works_on:
    - on-prem

breadcrumbs:
    - /gateway/

faqs:
  - q: How do I migrate from {{site.base_gateway}} open source (OSS) to {{site.ee_product_name}}?
    a: |
        You can migrate to {{site.ee_product_name}} using the `kong migrations` CLI commands.
        
        {:.danger}
        > **Warning:** This action is irreversible, therefore we strongly recommend [backing up](/gateway/upgrade/backup-and-restore/) your production data before migrating from {{site.base_gateway}} OSS to {{site.ee_product_name}}.
        
        You can only migrate to a {{site.ee_product_name}} version that supports the same OSS version. The latest version of {{site.base_gateway}} OSS is {{site.latest_gateway_oss_version}}.

        1. Download the {{site.ee_product_name}} package that matches your installed OSS version.
        1. Configure it to point to the same data store as your {{site.base_gateway}} OSS node.
           The migration command expects the data store to be up to date on any pending migration:

           ```sh
           kong migrations up [-c configuration_file]
           kong migrations -f finish [-c configuration_file]
           ```

           {:.warning}
           > **Caution**: {% include_cached /gateway/migration-finish-warning.md %}

        1. Confirm that all of the entities are now available on your {{site.ee_product_name}} node.
        1. (Optional) [Upgrade](/gateway/upgrade/) to your desired version of {{site.ee_product_name}}. 

no_wrap: true
versioned: true
next_steps:
  - text: Get started with {{site.base_gateway}}
    url: /gateway/get-started/
---

{% include install/gateway.html %}

{% include sections/faq.html %}

{% include sections/next_steps.html %}
