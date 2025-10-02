---
title: "Supported third-party dependencies for {{site.base_gateway}}"
content_type: policy
layout: reference

products:
  - gateway

breadcrumbs:
  - /gateway/

tags:
  - policy
  - support
search_aliases:
  - browsers
  - data stores
  - vaults
  - service mesh
  - S3 bucket

description: |
  This reference lists all of the tested and supported versions of {{site.base_gateway}}'s third-party dependencies.

related_resources:
  - text: "{{site.base_gateway}} version support policy"
    url: /gateway/version-support-policy/
  - text: Kong vulnerability patching process
    url: /gateway/vulnerabilities/
  - text: "{{site.base_gateway}} breaking changes"
    url: /gateway/breaking-changes/
  - text: "{{site.konnect_short_name}} compatibility"
    url: /konnect-platform/compatibility/

works_on:
  - on-prem
  - konnect
---

This page lists services used in day-to-day operation of {{site.base_gateway}} and the versions of these services that have been tested by Kong.
Using these services may be optional, or they may be required by {{site.base_gateway}} or certain plugins.

Unless otherwise noted, Kong supports the last two versions any third-party tool, plus the current managed version if available.

Other supported third-party tools:
* For identity providers supported by the OpenID Connect plugin, see the [OIDC plugin's documentation](/plugins/openid-connect/#supported-identity-providers).
* For supported AI providers, see the [AI Gateway providers documentation](/ai-gateway/ai-providers/).

{:.info}
> **Note:** Kong only tests compatibility against these tools and dependencies.
> Kong **does not** maintain, own, or provide user support for any of the third-party tools listed here,
> or for any AI providers and identity providers.

## Third-party tools

Kong supports the following third-party tools for each given {{site.base_gateway}} release version.

{:.info}
> Some third-party tools on this page don't have a version number. 
These tools are managed services and Kong provides compatibility with the currently released version.

{% assign releases = site.data.products.gateway.releases | reverse | where: "label", empty %}
{% navtabs "gateway-version" %}
{% for release in releases %}
{% unless release.sunset == true %}
{% assign tab_name = release.release %}
{% if release.lts %}{% assign tab_name = tab_name | append: ' LTS' %}{% endif %}
{% navtab {{ tab_name }} %}
  {% include_cached support/gateway-third-party.html release=release %}
{% endnavtab %}
{% endunless %}
{% endfor %}
{% endnavtabs %}

## Supported browsers

Kong supports the two latest stable versions and any extended support versions of the following “evergreen” desktop browsers:

{% include_cached support/browsers.html %}

[Chrome](https://www.chromium.org/chrome-release-channels/), 
[Firefox](https://support.mozilla.org/en-US/kb/switch-to-firefox-extended-support-release-esr), and 
[Edge](https://blogs.windows.com/msedgedev/2021/07/15/opt-in-extended-stable-release-cycle/) release a new major version every 4 weeks, 
with extended support available for 8 weeks.
