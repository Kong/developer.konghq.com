{%- capture snippet -%}
{% include how-tos/validations/env-variables/snippet.md variables=config.variables %}
{%- endcapture -%}
{% include works_on_wrapper.md on_prem_content=snippet konnect_content=snippet %}