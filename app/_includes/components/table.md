{% for row in include.rows -%}
{% assign first_col = include.columns | first -%}
{% for i in (1..heading_level) %}#{% endfor %} {{ row[first_col.key] | liquify }}
{% for column in include.columns offset:1 %}{% assign value = row[column.key] -%}
{% assign rendered = value | liquify | strip -%}
{{column.title | liquify}}: {% if value == true %}true{% elsif value == false %}false{% elsif rendered contains "
" %}|
{{rendered | indent: 2}}{% else %}{{rendered}}{% endif %}
{% endfor %}
{% endfor -%}