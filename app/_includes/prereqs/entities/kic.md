{% assign summary = 'Pre-configured entities' %}
{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

{% capture details_content %}

{% for service in include.data.services %}

Create the `{{ service.name }}` service:

```bash
kubectl apply -f {{ site.links.web }}/manifests/kic/{{ service.name }}-service.yaml
```

{% endfor %}

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/widgets.svg' %}
