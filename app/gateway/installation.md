---
title: "Install {{site.base_gateway}} on Linux"

description: |
  {{site.base_gate}} installation reference
content_type: reference
layout: reference
products:
   - gateway

related_resources:
  - text: "Managing {{site.base_gateway}} configuration"
    url: /gateway/manage-kong-conf/
   
works_on:
   - on-prem
---


@TODO


### FIPS install

{{site.base_gateway}} provides a FIPS 140-2 compliant package for Ubuntu 20.04, Ubuntu 22.04, Red Hat Enterprise 9, and Red Hat Enterprise 8. This package provides compliance for the core {{site.base_gateway}} product and all out of the box plugins. For more information, see the [FIPS reference page](/gateway/fips/).


{% navtabs %}
{% navtab "Ubuntu" %}
{% include prereqs/install/fips/ubuntu.md %}
{% endnavtab %}
{% navtab "Red Hat" %}
{% include prereqs/install/fips/red-hat.md %}
{% endnavtab %}
{% endnavtabs %}

