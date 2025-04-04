
{% assign page_title = page.example.title %}
{% if page_title == empty %}{% assign page_title = 'EMPTY TITLE' %}{% endif %}
{%- capture title -%}{{ page_title | liquify }}{% if page.min_version %}{% new_in page.min_version.gateway %}{% endif %}{%- endcapture -%}

## {{title}}

{{ page.example.description | liquify | markdoownify }}

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

## Set up the plugin

{% include components/plugin_config_example.html plugin_config_example=page.example %}
