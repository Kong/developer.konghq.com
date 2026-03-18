{% if page.output_format == 'markdown' -%}
[{{include.config.text | liquify}}]({{include.config.url}})
{% else %}
<a href="{{ include.config.url }}" class="no-icon {% if include.config.align %}self-{{ include.config.align }} {% endif %}">
  {{ include.config.text }}
</a>
{% endif %}