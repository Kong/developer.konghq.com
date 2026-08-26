---
title: Install {{site.base_gateway}}
subtitle: "Set up {{site.base_gateway}} with {{site.konnect_short_name}}, or install it on self-managed infrastructure."

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
        You can migrate using the `kong migrations` CLI.
        See the [OSS to Enterprise migration guide](/gateway/upgrade/migrate-oss-to-ee/) for step-by-step instructions.
  - q: "How do I install {{site.base_gateway}} on Windows?"
    a: |
      To install {{site.base_gateway}} on Windows, use [Docker](#docker). Kong does not provide a native Windows install method for {{site.base_gateway}}.
  - q: Where can I find all supported platforms and packaging options? 
    a: |
      To find all supported platforms and package types for {{site.base_gateway}}, see the [supported platforms and versions](/gateway/version-support-policy/#supported-versions) in the {{site.base_gateway}} version support policy.
      
      If you don't see your {{site.base_gateway}} version here, it has reached end of life and Kong no longer publishes any packages or images for it.
  - q: How do I install a downloaded package file?
    a: |
      If you have already downloaded a {{site.base_gateway}} package file, you can install it using your package manager. 
      
      For `.deb` files:

      ```sh
      sudo apt install --yes /path/to/kong-enterprise-edition_{{ include.release.major_minor_version }}_amd64.deb
      ```

      For `.rpm` files:
      ```
      sudo yum install -y kong-enterprise-edition-{{ include.release.major_minor_version }}
      ```

no_wrap: true
versioned: true
next_steps:
  - text: Get started with {{site.base_gateway}}
    url: /gateway/get-started/
---

{% include install/gateway.html %}

{% unless page.output_format == 'markdown' %}
{% include sections/faq.html %}

{% include sections/next_steps.html %}
{% endunless %}