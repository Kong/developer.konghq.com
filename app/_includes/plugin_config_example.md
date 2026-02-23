## {{include.title | liquify }}

{% if page.example.extended_description %}
{{ page.example.extended_description | liquify | markdownify }}
{% else %}
{{ page.example.description | liquify | markdownify }}
{% endif %}

{% unless page.example.requirements == empty %}

## Prerequisites

{% for requirement in page.example.requirements %}
* {{ requirement | liquify }}
{% endfor %}

{% endunless %}

{% unless page.example.variables == empty %}

## Environment variables

{% for variable in page.example.variables %}
* `{{ variable.value }}` {%- if variable.description -%}: {{variable.description | liquify }}{% endif%}
{% endfor %}

{% endunless %}

{% include components/plugin_config_example.html plugin_config_example=page.example entity='plugin' targets=include.targets entity=include.entity target_label=include.target_label %}
