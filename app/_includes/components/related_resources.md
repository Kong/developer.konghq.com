{% for related_resource in related_resources.items %}
- [{{related_resource.text | liquify}}]({{related_resource.url | liquify}})
{% endfor %}