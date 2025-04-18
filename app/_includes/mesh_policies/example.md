
{% assign page_title = page.example.title %}
{% if page_title == empty %}{% assign page_title = 'EMPTY TITLE' %}{% endif %}
{%- capture title -%}{{ page_title | liquify }}{% if page.min_version %}{% new_in page.min_version.mesh %}{% endif %}{%- endcapture -%}

## {{title}}

{{ page.example.description | liquify | markdoownify }}

{% unless page.example.requirements == empty %}

## Prerequisites

{% for requirement in page.example.requirements %}
* {{ requirement | liquify }}
{% endfor %}

{% endunless %}

## Configuration

{% policy_yaml namespace=page.example.namespace use_meshservice=page.example.use_meshservice %}
```yaml
{{page.example.config}}
```
{% endpolicy_yaml %}
