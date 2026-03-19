{% if page.output_format == 'markdown' -%}
{% include components/unordered_list.md config=include.config %}
{% else %}
{% include components/unordered_list.html config=include.config %}
{% endif %}