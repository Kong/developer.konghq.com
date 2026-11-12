{% assign today = 'now' | date: '%s' | plus: 0 -%}
{%- assign releases = site.data.products.ai-gateway.releases | where_exp: "r", "r.eol" -%}

{% table %}
columns:
  - title: Version
    key: version
  - title: Released date
    key: release_date
  - title: End of support
    key: eol
  - title: End of sunset support
    key: sunset
rows:
{% for release in releases -%}
{%- assign eol_timestamp = release.eol | date: '%s' | plus: 0 -%}
{%- if eol_timestamp < today -%}
{%- assign first_version = release.release | append: ".0" -%}
{%- assign release_date = release.release_date | default: site.data.products.ai-gateway.release_dates[first_version] | date: '%Y-%m-%d' %}
  - version: "{{ release.release }}"
    release_date: "{{ release_date }}"
    eol: "{{ release.eol | date: '%Y-%m-%d' }}"
    sunset: "{{ release.sunset_eol | date: '%Y-%m-%d' }}"
{%- endif -%}
{%- endfor %}
{% endtable %}
