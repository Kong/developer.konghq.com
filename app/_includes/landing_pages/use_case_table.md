{% if page.output_format == 'markdown' -%}
{% include components/use_case_table.md config=include.config %}
{%- else -%}
{% include components/use_case_table.html config=include.config %}
{%- endif -%}
