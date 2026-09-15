
{% assign page_title = page.example.title %}
{% if page_title == empty %}{% assign page_title = 'EMPTY TITLE' %}{% endif %}
{%- capture title -%}{{ page_title | liquify }}{% if page.min_version != empty %}{% new_in page.min_version.gateway %}{% endif %}{%- endcapture -%}

{% assign targets = site.data.entity_examples.config.targets %}

{% include plugin_config_example.md title=title targets=targets entity='plugin' target_label='Select an entity' %}

{% if page.credential_example %}
{% if page.output_format == 'markdown' %}
{% include components/plugin_credential_example.md credential_example=page.credential_example %}
{% else %}
{% include components/plugin_credential_example.html credential_example=page.credential_example %}
{% endif %}
{% endif %}
