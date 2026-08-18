{% assign attributes = site.data.plugins.otel-metrics.resource_attributes %}
{% table %}
columns:
  - title: Attribute
    key: attribute
  - title: Attribute description
    key: description
rows:
{% for attribute in attributes %}
  - id: {{ attribute[0] }}
    attribute: "`{{ attribute[0] }}`"
    description: |
{{attribute[1] | indent: 6}}
{% endfor %}
{% endtable %}
