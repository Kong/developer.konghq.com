{%- assign name = include.config.name -%}
{%- assign kind = include.config.kind -%}
{%- assign path = include.config.path -%}
{%- assign namespace = include.config.namespace | default: "kong" -%}
{%- capture get_command -%}
kubectl get -o yaml -n {{ namespace }} {{ kind | downcase }}
{%- endcapture -%}
{%- if include.config.name_selector -%}
{% capture name_selector %}
NAME=$({{ get_command | strip }} | yq '{{ include.config.name_selector | strip }}')
{%- endcapture %}
{%- assign name='$NAME' -%}
{%- endif -%}

```bash{{ name_selector }}
{{ get_command | strip }} {{ name }} \
  | yq '{{ path | strip }}'
```

You should see the value `{{ include.config.expected }}`.