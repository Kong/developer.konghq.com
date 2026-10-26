{% if page.output_format == 'markdown' %}
![{{include.config.alt_text}}]({{include.config.url}})
{% else %}
<img src="{{include.config.url}}" alt="{{include.config.alt_text}}"{% if include.config.expandable %} class="expandable-image"{% endif %} />
{% endif %}
