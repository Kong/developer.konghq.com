{% assign kind = include.config.kind -%}
{%- assign resource = include.config.resource -%}
{%- assign status_field = include.config.status_field | default: '.status.parents[?(@.parentRef.name=="kong")].conditions' -%}
{%- assign status_type = include.config.status_type | default: "Accepted" -%}
{%- assign expected = include.config.expected | default: "True" -%}
{%- assign namespace = include.config.namespace | default: "kong" -%}
{%- assign timeout = include.config.timeout | default: "30s" -%}
{%- if kind == "httproute" %}{% assign status_type = "Programmed" %}{% endif %}

Wait for the `{{ kind }}` to be `{{ expected }}`.

```bash
kubectl wait -n {{ namespace }} --timeout={{ timeout }} {{ kind | downcase }}/{{ resource }} \
  --for='jsonpath={% raw %}{{% endraw %}{{ status_field }}[?(@.type=="{{ status_type }}")].status }={{ expected }}'
```