{%- capture konnect_snippet -%}{% include how-tos/validations/rate-limit-check/snippet.md iterations=config.iterations url=config.konnect_url headers=config.headers sleep=config.sleep grep=config.grep output=config.output %}{%- endcapture -%}

{%- capture on_prem_snippet -%}{% include how-tos/validations/rate-limit-check/snippet.md iterations=config.iterations url=config.on_prem_url headers=config.headers sleep=config.sleep grep=config.grep output=config.output %}{%- endcapture -%}

{% include works_on_wrapper.md on_prem_content=on_prem_snippet konnect_content=konnect_snippet %}

{% if config.message %}
 On the last request, you should get a `{{config.status_code}}` response with the message `{{config.message}}`.
{% endif %}
