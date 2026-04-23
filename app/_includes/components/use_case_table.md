{% if include.heading_level %}{% assign level = include.heading_level %}{% else %}{% assign level = heading_level %}{% endif -%}
{% for row in include.config.rows -%}
{% for _ in (1..heading_level) -%}#{% endfor %} {{ row.usecase | liquify }}

{% for outcome in row.outcomes -%}
{% for column in include.config.columns -%}
{% assign value = outcome[column.key] | liquify | strip -%}
{% assign label = column.title | liquify | strip | split: "
" | first | strip -%}
{% if forloop.first %}- {{ label }}: {{ value }}
{% else %}  - {{ label }}: {{ value }}
{% endif -%}
{% endfor %}
{% endfor %}
{% endfor -%}
