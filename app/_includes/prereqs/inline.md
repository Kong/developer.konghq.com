{%- assign prereq = include.prereq -%}
{%- capture details_content -%}
{%- if prereq.content %}
{{ include.prereq.content | liquify }}
{%- elsif prereq.include_content -%}
{%- assign include_path = prereq.include_content | append: ".md" %}
{% include {{ include_path }} %}
{%- else -%}
    {%- raise "content or include_content must be set when using the `prereqs.inline` block" -%}
{%- endif -%}
{%- endcapture -%}
{%- assign summary = include.prereq.title -%}
{%- assign icon_url = prereq.icon_url -%}
{%- unless icon_url -%}
{%- assign icon_url = "/assets/icons/code.svg" -%}
{%- endunless -%}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url=icon_url %}