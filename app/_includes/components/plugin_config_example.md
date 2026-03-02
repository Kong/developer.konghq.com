{%- assign plugin_config_example = include.plugin_config_example -%}
{%- assign targets = plugin_config_example.targets -%}
{%- assign formats = plugin_config_example.formats -%}
{%- for example in plugin_config_example.examples -%}
{%- assign target = example.target.key -%}
{%- assign formatted_examples = example.formatted_examples -%}
### {{include.targets[target].label}}

{% for formatted_example in formatted_examples %}
{%- assign format = formatted_example.format -%}
#### {{ site.data.entity_examples.config.formats[format].label }}

{%- capture markdown_template %}{% include {{ formatted_example.template_file }} presenter=formatted_example.presenter render_context=true %}{% endcapture -%}
{{ markdown_template | rstrip }}
{% endfor %}
{%- endfor -%}