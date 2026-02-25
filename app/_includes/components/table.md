{% for row in include.rows -%}
{% for i in (1..heading_level) %}#{% endfor %} Entry
{% for column in include.columns %}{% assign value = row[column.key] -%}
{{column.title | liquify}}:{% if value == true %}true{% elsif value == false %}false{% else %} |
{{value | liquify | indent: 2}}{% endif %}
{% endfor %}
{% endfor -%}