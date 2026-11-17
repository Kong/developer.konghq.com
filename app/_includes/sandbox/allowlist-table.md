{%- assign allowlist_product = include.product | default: "gateway" -%}
{%- assign allowlist = site.data.sandbox_allowlist[allowlist_product] -%}
{%- assign allowlist_block = allowlist | where: "kind", include.kind | where: "mode", include.mode | first -%}
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
  {%- assign badge_text = "" -%}
  {%- if item.min_version and item.max_version -%}
    {%- assign badge_text = "v" | append: item.min_version | append: " to v" | append: item.max_version -%}
  {%- elsif item.max_version -%}
    {%- assign badge_text = "up to v" | append: item.max_version -%}
  {%- elsif item.min_version -%}
    {%- assign badge_text = "v" | append: item.min_version | append: "+" -%}
  {%- endif %}
      * `{{ item.name }}`
      {%- if badge_text != "" -%}
        {%- capture badge_html %}{% include badge.html text=badge_text css_class="new-in" %}{% endcapture %} {{ badge_html | strip_newlines | strip }}
      {%- endif -%}
{%- endfor -%}
{%- endfor %}
{% endtable %}
