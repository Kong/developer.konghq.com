{%- if config.step -%}
## {{site.llm_copy.konnect_snippet}}: {{config.title | liquify }}

{{config.content | liquify }}
{%- else -%}
{%- if page.works_on.size > 1 %}{% assign render_descriptions = true %}{% endif -%}
{%- assign indentation = 0 -%}{%- if config.indent -%}{% assign indentation = config.indent %}{%- endif -%}
{%- capture wrapper %}
{% if render_descriptions %}
{% for i in (1..heading_level) %}#{% endfor %} {{site.llm_copy.konnect_snippet}}
{% endif %}
{{config.content | liquify }}
{% endcapture %}
{{wrapper | indent: indentation}}
{% endif %}