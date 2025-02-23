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

{% assign releases = site.data.products.gateway.releases | reverse %}

{% navtabs %}
{% for release in releases %}
{% assign tab_name = release.release %}
{% if release.lts %}{% assign tab_name = tab_name | append: ' LTS' %}{% endif %}
{% navtab {{tab_name}} %}
  {% include support/gateway.html release=release %}
{% endnavtab %}
{% endfor %}
{% endnavtabs %}

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
