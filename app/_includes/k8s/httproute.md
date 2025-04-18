{%- assign path = include.path | default: '/echo' %}
{%- assign hostname = include.hostname | default: 'kong.example' %}
{%- assign name = include.name | default: 'echo' %}
{%- assign namespace = include.namespace | default: 'kong' %}
{%- assign service = include.service | default: 'echo' %}
{%- assign port = include.port | default: '1027' %}
{%- assign ingress_class = include.ingress_class | default: 'kong' %}
{%- assign route_type = include.route_type | default: 'PathPrefix' %}

{% capture the_code %}
{% navtabs "http-route" %}
{% navtab "Gateway API" %}
{% assign gwapi_version = "v1" %}

```bash
echo "
apiVersion: gateway.networking.k8s.io/{{ gwapi_version }}
kind: HTTPRoute
metadata:
  name: {{ name }}{% unless namespace == '' %}
  namespace: {{ namespace }}{% endunless %}
  annotations:{% if include.annotation_rewrite %}
    konghq.com/rewrite: '{{ include.annotation_rewrite }}'{% endif %}
    konghq.com/strip-path: 'true'
spec:
  parentRefs:
  - name: kong{% unless namespace == '' %}
    namespace: {{ namespace }}{% endunless %}{% unless include.skip_host %}
  hostnames:
  - '{{ hostname }}'{% endunless %}
  rules:
  - matches:
    - path:
        type: {{ route_type }}
        value: {{ path }}
    backendRefs:
    - name: {{ service }}
      kind: Service
      port: {{ port }}
" | kubectl apply -f -
```

{% endnavtab %}
{% navtab "Ingress" %}

```bash
echo "
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ name }}{% unless namespace == '' %}
  namespace: {{ namespace }}{% endunless %}
  annotations:{% if include.annotation_rewrite %}
    konghq.com/rewrite: '{{ include.annotation_rewrite }}'{% endif %}
    konghq.com/strip-path: 'true'
spec:
  ingressClassName: {{ ingress_class }}
  rules:
  - {% unless include.skip_host %}host: {{ hostname }}
    {% endunless %}http:
      paths:
      - path: {% if route_type == 'RegularExpression' %}/~{% endif %}{{ path }}
        pathType: ImplementationSpecific
        backend:
          service:
            name: {{ service }}
            port:
              number: {{ port }}
" | kubectl apply -f -
```

{% endnavtab %}
{% endnavtabs %}
{% endcapture %}

{% if include.indent %}
{{ the_code | indent: include.indent }}
{% else %}
{{ the_code }}
{% endif %}
