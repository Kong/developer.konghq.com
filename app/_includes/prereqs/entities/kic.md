{% assign summary = 'Required Kubernetes resources' %}
{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

{% capture details_content %}
{% if include.data.services %}
This how-to requires some Kubernetes services to be available in your cluster. These services will be used by the resources created in this how-to.

```bash{% for service in include.data.services %}
kubectl apply -f {{ site.links.web }}/manifests/kic/{{ service.name }}-service.yaml -n kong
{%- endfor %}
```
{: data-test-prereqs="block" }
{% endif %}
{% if include.data.routes %}

{% assign routeCount = include.data.routes | size %}
This how-to also requires {{ routeCount }} pre-configured route{% if routeCount > 1 %}s{% endif %}:

{% for route in include.data.routes %}
{% httproute %}
name: {{ route.name }}
matches: [{{ route | json_prettify }}]
skip_host: true
{% endhttproute %}
{% endfor %}

{% endif %}

{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/widgets.svg' %}
