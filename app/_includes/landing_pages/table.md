{% if page.output_format == 'markdown' -%}
{% include components/table.md columns=include.config.columns rows=include.config.rows item_title=include.config.item_title %}
{%- else -%}
{% include components/table.html columns=include.config.columns rows=include.config.rows item_title=include.config.item_title %}
{%- endif -%}