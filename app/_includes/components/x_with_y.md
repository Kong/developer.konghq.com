{% if include.config.headers %}### {{ include.config.headers[0] | liquify }}{% endif %}
{% for item in include.config.items %}
{%- assign include_path = "landing_pages/" | append: item.action.type | append : ".md" -%}
{%- capture description %}{%- include {{ include_path }} type=item.action.type config=item.action.config -%}{% endcapture -%}
{% if include.config.headers %}####{% else %}###{% endif %} Entry
task: |
{{item.text | liquify | indent: 2}}
description: |
{{description | lstrip | indent: 2}}
{% endfor %}