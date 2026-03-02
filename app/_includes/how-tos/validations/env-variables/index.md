{%- capture snippet -%}{% include how-tos/validations/env-variables/snippet.md variables=config.variables %}{%- endcapture -%}
{%- assign indentation = 0 -%}{%- if config.indent -%}{% assign indentation = config.indent %}{%- endif -%}
{%- capture wrapper %}{% include works_on_wrapper.md on_prem_content=snippet konnect_content=snippet %}{% endcapture -%}
{{wrapper | indent: indentation}}