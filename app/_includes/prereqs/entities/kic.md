{% assign summary = 'Required Kubernetes resources' %}
{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

{% capture details_content %}

This how-to requires some Kubernetes services to be available in your cluster. These services will be used by the resources created in this how-to.

```bash{% for service in include.data.services %}
kubectl apply -f {{ site.links.web }}/manifests/kic/{{ service.name }}-service.yaml -n kong
{%- endfor %}
```
{: data-test-prereqs="block" }

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/widgets.svg' %}
