{% for section in config.sections %}
## {{section.title}}
{% if section.description != empty %}
{{section.description}}
{% endif %}

{% for param in section.parameters %}
### {{param.name}}

{% if param.min_version %}
* Min Version: {{param.min_version.gateway}}
{%- endif -%}
{%- if param.removed_in -%}
* Removed in: {{param.removed_in.gateway}}
{%- endif -%}
{%- if param.defaultValue -%}
* Default: `{{param.defaultValue | escape}}`
{%- endif %}


{{param.description}}

{% endfor %}

{% endfor %}