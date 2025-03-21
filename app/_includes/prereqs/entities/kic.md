{% assign summary = 'Required Kubernetes resources' %}
{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

{% capture details_content %}

This how-to requires some additional resources to be created in your cluster.

```bash{% for service in include.data.services %}
kubectl apply -f {{ site.links.web }}/manifests/kic/{{ service.name }}-service.yaml -n kong
{%- endfor %}
```

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/widgets.svg' %}
