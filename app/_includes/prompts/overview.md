{% if page.extended_description %}
{{page.extended_description | liquify }}
{% else %}
{{ page.description | liquify }}
{% endif %}

## Prompts

{% html_tag type="dev" css_classes="grid grid-cols-1 md:grid-cols-2 gap-16" %}
{% for prompt in page.prompts %}
```text
{{ prompt | liquify }}
```
{:data-ask-kai="true"}
{% endfor %}
{% endhtml_tag %}