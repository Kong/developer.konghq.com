{% if include.heading_level %}{% assign level = include.heading_level %}{% else %}{% assign level = heading_level %}{% endif -%}
{% for row in include.rows %}
{% for i in (1..level) %}#{% endfor %} {{row.title}} Plugin
Plugin: {% if row.url %}[{{row.title}}]({{row.url}}){% else %}{{row.title}}{% endif %}
Plugin slug: {{row.slug}}
{%- if type == 'deployment_topologies' -%}
{% for column in include.columns -%}
{{column.title | liquify}}: {% if column.key == 'konnect_deployments' and row.values[column.key] == empty -%}Not supported in Konnect.{%- else -%}
    {%- if column.key == 'notes' -%}
    {% if row.values[column.key] %}|
{{row.values[column.key] | liquify | indent: 2}}{% else %}N/A{% endif -%}
    {%- else -%}
    {% for value in row.values[column.key] %}
    * {{value}}{% endfor %}{% endif %}
{% endif %}{% endfor %}
{%- elsif type == 'referenceable_fields' -%}
{% for column in include.columns -%}
{{column.title | liquify}}: |{% for value in row.values %}
    * {{value}}{% endfor %}
{% endfor %}
{% endif -%}
{% endfor -%}