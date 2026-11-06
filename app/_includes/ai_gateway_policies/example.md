
{% assign page_title = page.example.title %}
{% if page_title == empty %}{% assign page_title = 'EMPTY TITLE' %}{% endif %}
{%- capture title -%}{{ page_title | liquify }}{%- endcapture -%}

{% assign scope_labels = site.data.entity_examples.config.ai_gateway_scopes %}

{% include plugin_config_example.md title=title entity='policy' targets=scope_labels target_label='Select a scope' %}
{%- if page.output_format == 'markdown' %}
{% include ai_gateway_policies/attach_example.md targets=scope_labels %}
{%- else %}
{% include ai_gateway_policies/attach_example.html targets=scope_labels %}
{%- endif %}
