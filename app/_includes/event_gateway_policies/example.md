
{% assign page_title = page.example.title %}
{% if page_title == empty %}{% assign page_title = 'EMPTY TITLE' %}{% endif %}
{%- capture title -%}{{ page_title | liquify }}{% if page.min_version %}{% new_in page.min_version.event_gateway %}{% endif %}{%- endcapture -%}

{% assign targets = site.data.entity_examples.config.phases %}

{% include plugin_config_example.md title=page_title entity='policy' targets=targets target_label='Select a phase' %}