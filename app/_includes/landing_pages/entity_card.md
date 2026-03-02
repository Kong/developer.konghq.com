{% assign entity_id = include.config.entity -%}
{%- assign entities_list = site.gateway_entities -%}
{%- assign entity = entities_list | where_exp: "entity", "entity.entities contains entity_id" | first -%}
{%- assign url = entity.url | append: include.config.additional_url -%}
{% if page.output_format == 'markdown' -%}
{% include card.md title=entity.title description=entity.description cta_text='See reference' cta_url=url heading_level=include.heading_level %}
{%- else -%}
{% include card.html title=entity.title description=entity.description cta_text='See reference' cta_url=url %}
{% endif %}