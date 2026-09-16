{%- capture konnect_snippet -%}{% include how-tos/validations/request-check/snippet.md config=config.konnect_snippet_config %}{%- endcapture -%}

{%- capture on_prem_snippet -%}{% include how-tos/validations/request-check/snippet.md config=config.on_prem_snippet_config %}{%- endcapture -%}

{% include works_on_wrapper.md on_prem_content=on_prem_snippet konnect_content=konnect_snippet %}