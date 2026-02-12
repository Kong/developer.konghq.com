{%- assign hostname = include.hostname | default: 'kong.example' %}
{%- assign name = include.name | default: 'echo' %}
{%- assign namespace = include.namespace | default: 'kong' %}
{%- assign gateway_namespace = include.gateway_namespace | default: 'kong' %}
{%- assign ingress_class = include.ingress_class | default: 'kong' %}
{%- assign route_type = include.route_type | default: 'PathPrefix' | split: "," %}
{%- assign path = include.path | default: '/echo' | split: "," %}
{%- assign service = include.service | default: 'echo' | split: "," %}
{%- assign port = include.port | default: '1027'| split: "," %}

{% assign count = service.size | minus: 1 %}

{% capture the_code %}
{% navtabs "http-route" %}
{% unless include.disable_gateway %}
{% navtab "Gateway API" %}

```bash
echo "
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ name }}{% unless namespace == '' %}
  namespace: {{ namespace }}{% endunless %}
  annotations:{% if include.annotation_rewrite %}
    konghq.com/rewrite: '{{ include.annotation_rewrite | replace: "$", "\$" }}'{% endif %}{% if include.annotation_plugins %}
    konghq.com/plugins: {{ include.annotation_plugins }}{% endif %}
    konghq.com/strip-path: 'true'
spec:
  parentRefs:
  - name: kong{% unless namespace == '' %}
    namespace: {{ gateway_namespace }}{% endunless %}{% if include.section_name %}
    sectionName: {{ include.section_name }}{% endif %}{% unless include.skip_host %}
  hostnames:
  - '{{ hostname }}'{% endunless %}
  rules:{% for i in (0..count) %}
  - matches:
    - path:
        type: {{ route_type[i] }}
        value: {{ path[i] }}
    backendRefs:
    - name: {{ service[i] }}
      kind: Service
      port: {{ port[i] }}{% endfor %}
" | kubectl apply -f -
```

{% endnavtab %}
{% endunless %}
{% unless include.disable_ingress %}
{% navtab "Ingress" %}

```bash
echo "
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ name }}{% unless namespace == '' %}
  namespace: {{ namespace }}{% endunless %}
  annotations:{% if include.annotation_rewrite %}
    konghq.com/rewrite: '{{ include.annotation_rewrite | replace: "$", "\$" }}'{% endif %}
    konghq.com/strip-path: 'true'
spec:
  ingressClassName: {{ ingress_class }}{% if include.section_name == 'https' %}
  tls:
    - secretName: {{ hostname }}
      hosts:
        - {{ hostname }}{% endif %}
  rules:{% for i in (0..count) %}
  - {% unless include.skip_host %}host: {{ hostname }}
    {% endunless %}http:
      paths:
      - path: {% if route_type[i] == 'RegularExpression' %}/~{% endif %}{{ path[i] }}
        pathType: ImplementationSpecific
        backend:
          service:
            name: {{ service[i] }}
            port:
              number: {{ port[i] }}{% endfor %}
" | kubectl apply -f -
```

{% endnavtab %}
{% endunless %}
{% endnavtabs %}
{% endcapture %}

{% if include.indent %}
{{ the_code | indent: include.indent }}
{% else %}
{{ the_code }}
{% endif %}
