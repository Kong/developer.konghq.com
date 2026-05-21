{% if page.output_format == 'markdown' -%}
{% include components/x_with_y.md config=include.config %}
{%- else -%}
{% include components/x_with_y.html config=include.config %}
{%- endif -%}