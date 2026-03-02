{% for section in config.sections %}
## {{section.title}}
{% if section.description != empty %}
{{section.description}}
{% endif %}

{% for param in section.parameters %}
### {{param.name}}
* Parameter: {{param.name}}
* Description: |
{{param.description | indent: 2}}
* Min Version: {% if param.min_version %}{{param.min_version.gateway}}{% else %}N/A{% endif %}
* Removed in: {% if param.removed_in %}{{param.removed_in.gateway}}{% else %}N/A{% endif %}
* Default value: {% if param.defaultValue %}{{param.defaultValue | escape}}{% else %}none{% endif %}
{% endfor %}
{% endfor %}