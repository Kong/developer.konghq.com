{%- assign step = include.step -%}
{% capture details_content %}
{%- if step.content -%}
{{ step.content }}
{%- elsif step.include_content -%}
{%- assign include_path = step.include_content | append: ".md" -%}
{% include {{ include_path }} %}
{%- else -%}
    {%- raise "content or include_content must be set when using the `cleanup.inline` block" -%}
{%- endif -%}
{%- endcapture -%}
{%- assign summary = include.step.title -%}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url=step.icon_url %}