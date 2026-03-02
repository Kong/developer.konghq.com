{% if page.output_format == 'markdown' -%}
{% include icon_card.md icon=include.config.icon title=include.config.title cta_url=include.config.cta.url heading_level=include.heading_level %}
{%- else -%}
{% include icon_card.html icon=include.config.icon title=include.config.title cta_url=include.config.cta.url %}
{% endif %}