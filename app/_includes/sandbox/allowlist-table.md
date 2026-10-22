{%- assign allowlist_product = include.product | default: "gateway" -%}
{%- assign allowlist = site.data.sandbox_allowlist[allowlist_product] -%}
{%- assign allowlist_block = allowlist | where: "kind", include.kind | where: "mode", include.mode | first -%}
{%- assign latest_release = site.data.products.gateway.releases | where: "latest", true | first -%}
{% table %}
columns:
  - title: Group
    key: group
  - title: Available
    key: names
rows:
{%- for group in allowlist_block.groups %}
  - group: "`{{ group.id }}`"
    names: |-
{%- for item in group.names -%}
  {%- if item.max_version and item.max_version != latest_release.release -%}{%- continue -%}{%- endif %}
      * `{{ item.name }}`
      {%- if item.min_version -%}
        {%- capture min_version_badge %}{% new_in item.min_version %}{% endcapture %} {{ min_version_badge | strip_newlines | strip }}
      {%- endif -%}
{%- endfor -%}
{%- endfor %}
{% endtable %}
