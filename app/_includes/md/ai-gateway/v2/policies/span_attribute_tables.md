{%- assign spans = site.data.ai-gateway.v1.otel-span-attributes.spans -%}
{%- assign attributes = site.data.ai-gateway.v1.otel-span-attributes.attributes -%}
{%- assign span_names = include.span_names | split: ',' -%}
{% for span in spans %}
{% if include.span_names %}
{% assign found = false %}
{% for span_name in span_names %}
{% assign stripped = span_name | strip %}
{% if span.name == stripped %}
{% assign found = true %}
{% break %}
{% endif %}
{% endfor %}
{% unless found %}{% continue %}{% endunless %}
{% endif %}
#### {{ span.title | default: span.name }}{% if span.min_version != "" %} {% new_in span.min_version %}{% endif %}

{{ span.description }}

{% if span.title and span.title != span.name %} The following span attributes use the `{{ span.name }}` prefix{% if span.name == "kong.a2a" %} or the `rpc` prefix{% endif %}:{% endif %} 

<!-- vale off -->
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
{% endfor %}
<!-- vale on -->
