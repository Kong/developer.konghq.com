{% assign entity_id = include.config.entity %}

{% assign entities_list = site.gateway_entities %}
{% assign entity = entities_list | where_exp: "entity", "entity.entities contains entity_id" | first %}

{% capture cta %}
    <a href="{{ entity.url }}">
    See reference &rarr;
    </a>
{% endcapture %}

{% include card.html title=entity.title description=entity.description cta=cta %}