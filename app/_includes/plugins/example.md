
{% assign page_title = page.example.title %}
{% if page_title == empty %}{% assign page_title = 'EMPTY TITLE' %}{% endif %}
{%- capture title -%}{{ page_title | liquify }}{% if page.min_version != empty %}{% new_in page.min_version.gateway %}{% endif %}{%- endcapture -%}

{% assign targets = site.data.entity_examples.config.targets %}

{% include plugin_config_example.md title=page_title targets=targets entity='plugin' target_label='Select an entity' %}
