{% for row in include.rows -%}
{% assign first_col = include.columns | first -%}
{% for i in (1..heading_level) %}#{% endfor %} {{ row[first_col.key] | liquify }}
{% for column in include.columns offset:1 %}{% assign value = row[column.key] -%}
{{column.title | liquify}}: {% if value == true %}true{% elsif value == false %}false{% else %}|
{{value | liquify | indent: 2}}{% endif %}
{% endfor %}
{% endfor -%}
