---
title: Install {{site.base_gateway}}
subtitle: "{{site.base_gateway}} is a low-demand, high-performing API gateway. You can set up {{site.base_gateway}} with Konnect, or install it on various self-managed systems."

description: "{{site.base_gateway}} installation options."

products:
    - gateway

content_type: reference
layout: install

works_on:
    - on-prem

breadcrumbs:
    - /gateway/

faqs:
  - q: How do I migrate from {{site.base_gateway}} open source (OSS) to {{site.base_gateway}} Enterprise?
    a: |
        You can migrate to {{site.base_gateway}} Enterprise using the `kong migrations` CLI commands.
        
        {:.danger}
        > **Warning:** This action is irreversible, therefore we strongly recommend [backing up](/gateway/upgrade/backup-and-restore/) your production data before migrating from {{site.base_gateway}} OSS to {{site.ee_product_name}}.
        
        You can only migrate to a {{site.ee_product_name}} version that supports the same OSS version. For example, if you want to migrate to {{site.ee_product_name}} 3.10, you must upgrade to {{site.base_gateway}} OSS 3.10 first.

        1. Download the {{site.ee_product_name}} package and configure it to point to the same data store as your {{site.base_gateway}} OSS node. The migration command expects the data store to be up to date on any pending migration:
           ```sh
           kong migrations up [-c configuration_file]
           kong migrations -f finish [-c configuration_file]
           ```

           {:.warning}
           > **Caution**: {% include_cached /gateway/migration-finish-warning.md %}

        1. Confirm that all of the entities are now available on your {{site.ee_product_name}} node.

no_wrap: true
versioned: true
---

{% include install/gateway.html %}

{% include sections/faq.html %}