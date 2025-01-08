```yaml
apiVersion: configuration.konghq.com/v1
kind: Kong{{ include.presenter.k8s_entity_type }}
metadata:
  name: {{ include.presenter.data.name }}
  annotations:
    kubernetes.io/ingress.class: kong
{% if include.presenter.data.tags %}    konghq.com/tags: {{ include.presenter.data.tags | join:", " }}
{%- endif -%}
upstreamRef:
    name: example_upstream
{% for v in include.presenter.data -%}
{%- unless v[0] == "tags" -%}
{{ v[0] }}: {{ v[1] }}
{%- endunless -%}
{% endfor -%}
```