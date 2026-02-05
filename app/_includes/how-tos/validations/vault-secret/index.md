{%- capture konnect_snippet -%}{% include how-tos/validations/vault-secret/snippet.md container=config.container.konnect secret=config.secret command=config.command %}{%- endcapture -%}

{%- capture on_prem_snippet -%}{% include how-tos/validations/vault-secret/snippet.md container=config.container.on_prem secret=config.secret command=config.command %}{%- endcapture -%}

{% include works_on_wrapper.md on_prem_content=on_prem_snippet konnect_content=konnect_snippet %}