---
title: "{{site.ee_product_name}} Version Support"
content_type: reference
layout: reference

tier: enterprise

products:
    - gateway

description: placeholder

related_resources:
  - text: "Secure {{site.base_gateway}}"
    url: /gateway/security/
---

@todo

Content from https://docs.konghq.com/gateway/latest/support-policy/#bug-fix-guidelines

## Marketplaces

Kong Gateway Enterprise is available through the following marketplaces:

{% for marketplace in site.data.products.gateway.marketplaces %}
* {{ marketplace }}
{% endfor %}

## Supported public cloud deployment platforms

Kong Gateway Enterprise supports the following public cloud deployment platforms:

{% for platform in site.data.products.gateway.cloud_deployment_platforms %}
* {{ platform }}
{% endfor %}