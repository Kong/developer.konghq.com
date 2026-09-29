{%- if page.works_on.size > 1 -%}{% assign render_descriptions = true %}{%- endif -%}
{%- if page.works_on contains 'konnect' -%}
{%- if render_descriptions -%}{{site.llm_copy.konnect_snippet}}{%- endif %}
{% include how-tos/validations/request-check/snippet.md config=config.konnect_snippet_config %}
{%- endif -%}

{%- if page.works_on contains 'on-prem' -%}
{%- if render_descriptions -%}{{site.llm_copy.on_prem_snippet}}{%- endif %}
{% include how-tos/validations/request-check/snippet.md config=config.on_prem_snippet_config %}
{%- endif -%}