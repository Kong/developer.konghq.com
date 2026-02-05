{%- capture konnect_snippet -%}{% include how-tos/validations/grpc-check/snippet.md url=config.konnect_url method=config.method payload=config.payload response=config.response authority=config.authority port=config.port plaintext=config.plaintext %}{%- endcapture -%}

{%- capture on_prem_snippet -%}{% include how-tos/validations/grpc-check/snippet.md url=config.on_prem_url method=config.method payload=config.payload response=config.response authority=config.authority port=config.port plaintext=config.plaintext %}{%- endcapture -%}

{% include works_on_wrapper.md on_prem_content=on_prem_snippet konnect_content=konnect_snippet %}