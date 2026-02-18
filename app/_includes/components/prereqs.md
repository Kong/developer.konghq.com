{%- assign product=page.products[0] -%}
{%- for prereq in prereqs.inline_before %}
{% include prereqs/inline.md prereq=prereq %}
{%- endfor -%}
{%- if prereqs.konnect_auth_only? -%}
{% include prereqs/products/konnect-auth-only.md tier=include.tier %}
{%- endif -%}
{% for prereq in prereqs.cloud -%}
{%- assign prereq_include = 'prereqs/cloud/' | append: prereq[0] | append: '.md' %}{%- assign config = prereq[1] -%}
{% include {{ prereq_include }} config=config products=prereqs.products %}
{%- endfor -%}
{%- if prereqs.kubernetes.gateway_api -%}
{% include prereqs/kubernetes/gateway-api.md config=prereqs.kubernetes product=product %}
{%- endif -%}
{%- if prereqs.kubernetes.prometheus -%}
{% include prereqs/kubernetes/prometheus.md config=prereqs.kubernetes %}
{%- endif -%}
{%- if prereqs.kubernetes.keycloak -%}
{% include prereqs/kubernetes/keycloak.md config=prereqs.kubernetes.keycloak %}
{%- endif -%}
{% if prereqs.skip_product != true -%}
{%- if page.products and prereqs.render_works_on? -%}
{%- if page.products contains 'gateway' or page.products contains 'ai-gateway' -%}
{%- if page.works_on contains 'konnect' -%}
{%- assign variables = prereqs.konnect -%}
{%- assign ports = prereqs.ports -%}
{% include prereqs/products/konnect.md tier=include.tier env_variables=variables ports=ports %}
{%- endif -%}
{%- if page.works_on contains 'on-prem' -%}
{%- assign variables=prereqs['gateway'] -%}
{% include prereqs/products/gateway.md rbac=page.rbac env_variables=variables %}
{%- endif -%}
{%- endif -%}
{%- if page.products contains 'kic'  -%}
{% include prereqs/kubernetes/kic-konnect-cp.md prereqs=prereqs %}
{%- endif -%}
{%- for product in prereqs.products %}
{%- assign product_include = 'prereqs/products/' | append: product | append: '.md' -%}
{%- if page.works_on -%}
{%- if page.works_on contains 'konnect' -%}
{% include {{ product_include }} prereqs=prereqs topology="konnect" %}
{%- endif -%}
{%- if page.works_on contains 'on-prem' -%}
{% include {{ product_include }} prereqs=prereqs topology="on-prem" %}
{%- endif -%}
{%- else -%}
{% include {{ product_include }} prereqs=prereqs %}
{%- endif -%}
{%- endfor -%}
{%- endif -%}
{%- endif -%}
{%- for tool in prereqs.tools -%}
{%- assign tool_include = 'prereqs/tools/' | append: tool | append: '.md' -%}
{%- capture tool_include_exists %}{% include_exists tool_include %}{% endcapture -%}
{%- if tool_include_exists == 'true' -%}
{% include {{ tool_include }} %}
{%- endif -%}
{%- endfor -%}
{%- if prereqs.operator.konnect.auth -%}
{% include prereqs/operator/konnect_auth.md config=prereqs.operator.konnect %}
{%- endif -%}
{%- if prereqs.operator.konnect.control_plane -%}
{% include prereqs/operator/konnect_control_plane.md config=prereqs.operator.konnect %}
{%- endif -%}
{%- if prereqs.operator.konnect.konnectextension -%}
{% include prereqs/operator/konnectextension.md config=prereqs.operator.konnect %}
{%- endif -%}
{%- if prereqs.operator.konnect.network -%}
{% include prereqs/operator/konnect_network.md config=prereqs.operator.konnect %}
{%- endif -%}
{%- if prereqs.entities? -%}
{%- if product == 'operator' %}{% assign product='kic' %}{% endif %}
{%- assign prereq_path = "prereqs/entities/" | append: product | append: ".md" -%}
{% include {{ prereq_path }} data=prereqs.data %}
{%- endif -%}
{%- for prereq in prereqs.inline_without_position %}
{% include prereqs/inline.md prereq=prereq %}
{% endfor -%}