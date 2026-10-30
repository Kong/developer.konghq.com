
{% assign page_title = page.example.title %}
{% if page_title == empty %}{% assign page_title = 'EMPTY TITLE' %}{% endif %}
{%- capture title -%}{{ page_title | liquify }}{% if page.min_version %}{% new_in page.min_version.ai-gateway %}{% endif %}{%- endcapture -%}

{% assign targets = site.data.entity_examples.config.ai_gateway_scopes %}

{% include plugin_config_example.md title=title entity='policy' targets=targets target_label='Select a scope' target_note='/ai_gateway_policies/target_note.md' target_example='/ai_gateway_policies/target_example.md' %}
