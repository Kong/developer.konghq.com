{%- capture konnect_snippet -%}{% include how-tos/validations/unauthorized-check/snippet.md url=config.konnect_url headers=config.headers %}
{%- endcapture -%}

{%- capture on_prem_snippet -%}{% include how-tos/validations/unauthorized-check/snippet.md url=config.on_prem_url headers=config.headers %}{%- endcapture -%}

{% include works_on_wrapper.md on_prem_content=on_prem_snippet konnect_content=konnect_snippet %}