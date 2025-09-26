
{% assign page_title = page.example.title %}
{% if page_title == empty %}{% assign page_title = 'EMPTY TITLE' %}{% endif %}
{%- capture title -%}{{ page_title | liquify }}{% if page.min_version %}{% new_in page.min_version.mesh %}{% endif %}{%- endcapture -%}

## {{title}}

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

## Configuration

```yaml
{{page.example.config}}
```
