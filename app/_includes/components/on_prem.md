{%- if config.step -%}
## {{site.llm_copy.on_prem_snippet}}: {{config.title | liquify }}

{{config.content | liquify }}
{%- else -%}
{%- assign indentation = 0 -%}{%- if config.indent -%}{% assign indentation = config.indent %}{%- endif -%}
{%- capture wrapper %}
{% for i in (1..heading_level) %}#{% endfor %} {{site.llm_copy.on_prem_snippet}}

{{config.content | liquify }}
{% endcapture %}
{{wrapper | indent: indentation}}
{% endif %}