{%- if page.works_on.size > 1 -%}{% assign render_descriptions = true %}{%- endif -%}
{%- if page.works_on contains 'konnect' -%}
{%- if render_descriptions -%}{{site.llm_copy.konnect_snippet}}{%- endif %}
{% include how-tos/validations/request-check/snippet.md url=config.konnect_url headers=config.headers body=config.body method=config.method %}
{%- endif -%}

{%- if page.works_on contains 'on-prem' -%}
{%- if render_descriptions -%}{{site.llm_copy.on_prem_snippet}}{%- endif %}
{% include how-tos/validations/request-check/snippet.md url=config.on_prem_url headers=config.headers body=config.body method=config.method %}
{%- endif -%}