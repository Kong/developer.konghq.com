## Description

{{ page.example.description | liquify | markdoownify }}

{% if page.example.requirements %}

## Prerequisites

{% for requirement in page.example.requirements %}
* {{ requirement | liquify }}
{% endfor %}

{% endif %}

{% if page.example.variables %}

## Environment variables

{% for variable in page.example.variables %}
* `{{ variable.value }}` {%- if variable.description -%}: {{variable.description | liquify }}{% endif%}
{% endfor %}

{% endif %}

## Set up the plugin

{% include components/plugin_config_example.html plugin_config_example=page.example %}
