{%- assign metrics = site.data.ai-gateway.v2.otel-metrics.metrics -%}
{%- assign attributes = site.data.ai-gateway.v2.otel-metrics.attributes -%}
{% for metric in metrics %}
{% if include.metric_prefixes %}
{% assign found = false %}
{% for prefix in include.metric_prefixes | split: ',' %}
{% if metric.name | slice: 0, prefix.size | strip == prefix | strip %}
{% assign found = true %}
{% break %}
{% endif %}
{% endfor %}
{% unless found %}{% continue %}{% endunless %}
{% endif %}
#### {{metric.name}}{% if metric.min_version != "" %} {% new_in metric.min_version %}{% endif %}

{{metric.description}}

{% if metric.unit %}- **Instrument unit**: `{{metric.unit}}`{% endif %}
{% if metric.type %}- **Instrument type**: `{{metric.type}}`{% endif %}
{% if metric.attributes %}- **Attributes**:
{% capture attrs_table %}
{% table %}
vertical_align: middle
columns:
  - title: Attribute
    key: attribute
  - title: Attribute description
    key: description
rows:
{% for attribute in metric.attributes %}
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
