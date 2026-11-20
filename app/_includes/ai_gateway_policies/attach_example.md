{%- assign attach_target_count = 0 -%}
{%- for example in page.example.examples -%}
{%- if example.data.global == false -%}{%- assign attach_target_count = attach_target_count | plus: 1 -%}{%- endif -%}
{%- endfor -%}
{%- if attach_target_count > 0 -%}
### Attach the policy

{% for example in page.example.examples -%}
{%- if example.data.global == false -%}
{%- assign target = example.target.key -%}
#### {{ include.targets[target].label }}

{% for formatted_example in example.attach_example.formatted_examples -%}
{%- assign format = formatted_example.format -%}
{%- capture attach_note %}{% include /ai_gateway_policies/target_note.md example=example targets=include.targets %}{% endcapture -%}
{%- capture attach_snippet %}{% include /ai_gateway_policies/target_example.md example=example format=format %}{% endcapture -%}
{%- capture attach_format_block -%}
##### {{ site.data.entity_examples.config.formats[format].label }}

{{ attach_note | strip }}

{{ attach_snippet | strip }}

{%- endcapture -%}
{{ attach_format_block }}
{% endfor -%}
{%- endif -%}
{%- endfor -%}
{%- endif -%}
