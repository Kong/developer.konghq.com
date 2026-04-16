{%- assign spans = site.data.plugins.otel-span-attributes.spans -%}
{%- assign attributes = site.data.plugins.otel-span-attributes.attributes -%}
{%- assign span_names = include.span_names | split: ',' -%}
{% for span in spans %}
{% if include.span_names %}
{% assign show_span = false %}
{% for span_name in span_names %}
{% assign span_name = span_name | strip %}
{% if span.name == span_name %}
{% assign show_span = true %}
{% endif %}
{% endfor %}
{% unless show_span %}{% continue %}{% endunless %}
{% endif %}
#### {{ span.title | default: span.name }}{% if span.title and span.title != span.name %} (`{{ span.name }}`){% endif %}{% if span.min_version %} {% new_in span.min_version %}{% endif %}

{{ span.description }}

{% if span.attributes %}- **Attributes**:
{% capture attrs_table %}
{% table %}
vertical_align: middle
columns:
  - title: Attribute
    key: attribute
  - title: Attribute description
    key: description
rows:
{% for attribute in span.attributes %}
  - id: "{{attribute}}"
    attribute: "`{{ attribute }}`"
    description: |
{{attributes[attribute] | indent: 6}}
{% endfor %}
{% endtable %}
{% endcapture %}
{{attrs_table | indent: 2}}
{% else %}- **No attributes**{% endif %}
{% endfor %}
