{%- assign metrics = site.data.plugins.otel-metrics.metrics -%}
{%- assign attributes = site.data.plugins.otel-metrics.attributes -%}
{%- assign metric_prefixes = include.metric_prefixes | split: ',' -%}
{% for metric in metrics %}
{% if include.metric_prefixes %}
{% assign show_metric = false %}
{% for prefix in metric_prefixes %}
{% assign prefix = prefix | strip %}
{% assign metric_prefix = metric.name | slice: 0, prefix.size %}
{% if metric_prefix == prefix %}
{% assign show_metric = true %}
{% endif %}
{% endfor %}
{% unless show_metric %}{% continue %}{% endunless %}
{% endif %}
#### {{metric.name}}{% if metric.min_version %} {% new_in metric.min_version %}{% endif %}

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
