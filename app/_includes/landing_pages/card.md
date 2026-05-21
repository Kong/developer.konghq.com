{% if page.output_format == 'markdown' %}
{% include card.md icon=include.config.icon title=include.config.title description=include.config.description cta_url=include.config.cta.url cta_text=include.config.cta.text featured=include.config.featured ctas=include.config.ctas id=include.config.id heading_level=include.heading_level%}
{%- else -%}
{% include card.html icon=include.config.icon title=include.config.title description=include.config.description cta_url=include.config.cta.url cta_text=include.config.cta.text featured=include.config.featured ctas=include.config.ctas id=include.config.id %}
{% endif %}