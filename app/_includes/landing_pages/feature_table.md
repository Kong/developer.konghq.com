{% if page.output_format == 'markdown' -%}
{% include components/feature_table.md columns=include.config.columns rows=include.config.features item_title=include.config.item_title %}
{% else -%}
{% include components/feature_table.html columns=include.config.columns rows=include.config.features item_title=include.config.item_title %}
{% endif -%}