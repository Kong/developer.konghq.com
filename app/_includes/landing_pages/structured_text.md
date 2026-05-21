{% if page.output_format == 'markdown' %}
{% include components/structured_text.md config=include.config %}
{% else %}
{% include components/structured_text.html config=include.config %}
{% endif %}