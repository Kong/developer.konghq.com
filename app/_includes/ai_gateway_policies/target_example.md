{%- if example.data.global == false -%}
{%- assign attach_example = example.attach_example -%}
{%- for formatted_example in attach_example.formatted_examples -%}
{%- if formatted_example.format == include.format -%}
{%- case include.format -%}
{%- when 'konnect-api' -%}
{% include components/entity_example/format/snippets/konnect-api.md presenter=formatted_example.presenter %}
{%- when 'terraform' -%}
{% include components/entity_example/format/snippets/terraform.md presenter=formatted_example.presenter %}
{%- when 'kongctl' -%}
{% include components/entity_example/format/snippets/kongctl.md presenter=formatted_example.presenter %}
{%- endcase -%}
{%- endif -%}
{%- endfor -%}
{%- endif -%}
