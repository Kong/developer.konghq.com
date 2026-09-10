{% if page.output_format == 'markdown' -%}
[{{include.config.text | liquify}}]({{include.config.url}})
{% else %}
<a href="{{ include.config.url }}" target="_blank"{% if include.config.url contains 'https://' %} rel="noopener nofollow noreferrer"{% endif %} class="no-icon {% if include.config.align %} self-{{ include.config.align }} {% endif %}">
  <button class="button button--primary">{{ include.config.text | liquify }}</button>
</a>
{% endif%}