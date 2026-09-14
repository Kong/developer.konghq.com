{%- assign drop = include.credential_example -%}
## Create a Consumer and credential

{% for formatted_example in drop.formatted_examples -%}{%- assign format = formatted_example.format %}
#### {{ site.data.entity_examples.config.formats[format].label }}

{% capture markdown_template %}{% include {{ formatted_example.template_file }} presenter=formatted_example.presenter %}{% endcapture -%}
{{ markdown_template | rstrip }}
{% endfor -%}
