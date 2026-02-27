{% if include.heading_level %}{% assign level = include.heading_level %}{% else %}{% assign level = heading_level %}{% endif -%}
{% for row in include.rows %}
{% for i in (1..level) %}#{% endfor %} {% if include.item_title %}{{row.title}}{% else %}Entry{% endif %}
{% unless include.compatibility_table %}{% if include.item_title %}{{include.item_title}}{% else %}title{% endif %}: {% if row.url %}[{{row.title | liquify}}]({{row.url}}){% else %}{{row.title | liquify | rstrip}}{% endif -%}{% endunless %}
{% if row.subtitle %}subtitle: {{row.subtitle | liquify}}{% endif -%}
{% for column in include.columns %}{% assign value = row[column.key] -%}
{% if include.compatibility_table %}{{include.item_title}} {{column.title}}{% else %}{{column.title}}{% endif %}: {% if value == true %}Supported{% elsif value == false %}Not Supported{% else %}|
{{ value | liquify | indent: 2}}{% endif %}
{% endfor -%}
{% endfor %}