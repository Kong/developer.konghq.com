{%- assign spans = site.data.ai-gateway.v2.otel-span-attributes.spans -%}
{%- assign attributes = site.data.ai-gateway.v2.otel-span-attributes.attributes -%}
{% for span in spans %}
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
