
{% if include.config.cta %}
{% capture cta %}{% include landing_pages/cta.md config=include.config.cta %}{% endcapture %}
{% endif %}

{% include card.html icon=include.config.icon title=include.config.title description=include.config.description cta=cta %}