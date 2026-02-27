{% for row in page.rows %}
{% if row.header %}{% assign heading_level = row.header.type | remove: 'h' | plus: 0 %}{% include llm/landing_pages/header.md config=row.header %}{% endif -%}
{% if row.columns -%}
{% for column in row.columns %}{%- if column.header %}{% include llm/landing_pages/header.md config=column.header %}{% endif -%}
{% for entry in column.blocks -%}
{%- assign include_path = "landing_pages/" | append: entry.type | append : ".md" -%}
{% include {{ include_path }} type=entry.type config=entry.config tab_group=entry.tab_group %}
{% endfor -%}
{% endfor -%}
{% endif -%}
{% endfor %}