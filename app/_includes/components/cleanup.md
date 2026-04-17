{%- if page.products[0] == "kic" -%}
{%- if page.prereqs.entities.services -%}
{%- capture details_content -%}
```bash{% for service in page.prereqs.entities.services %}
kubectl delete -n kong -f {{ site.links.web }}/manifests/kic/{{ service }}.yaml
{%- endfor %}
```
{%- endcapture -%}
{%- if page.prereqs.entities.services -%}
{% include how-tos/prereq_cleanup_item.html summary="Delete created Kubernetes resources" details_content=details_content icon_url='/assets/icons/widgets.svg' %}
{%- endif -%}
{%- endif -%}
{%- endif -%}
{%- for prereq in page.prereqs.cloud %}
{%- assign prereq_include = 'cleanup/cloud/' | append: prereq[0] | append: '.md' -%}
{%- assign config = prereq[1] -%}
{% include {{ prereq_include }} config=config %}
{%- endfor -%}
{%- for step in cleanup.inline %}
  {%- if step.include_content == 'cleanup/products/gateway' -%}
    {%- assign deployment_topology = 'on-prem' -%}
  {%- elsif step.include_content == 'cleanup/platform/konnect' -%}
    {%- assign deployment_topology = 'konnect' -%}
  {%- endif -%}
{% include cleanup/inline.md step=step %}
{%- endfor -%}