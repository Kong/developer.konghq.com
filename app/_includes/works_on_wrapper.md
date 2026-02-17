{%- assign indentation = 0 -%}{%- if config.indent -%}{% assign indentation = config.indent %}{%- endif -%}
{%- capture wrapper -%}
{%- if page.works_on.size > 1 %}{% assign render_descriptions = true %}{% endif -%}
{%- if page.works_on contains 'konnect' %}
{% if render_descriptions %}{% for i in (1..heading_level) %}#{% endfor %}{{site.llm_copy.konnect_snippet}}{% endif %}

{{include.konnect_content}}{% endif %}
{% if page.works_on contains 'on-prem' %}
{% if render_descriptions %}{% for i in (1..heading_level) %}#{% endfor %} {{site.llm_copy.on_prem_snippet}}{% endif %}

{{include.on_prem_content}}{% endif %}
{% endcapture -%}
{{wrapper | indent: indentation}}