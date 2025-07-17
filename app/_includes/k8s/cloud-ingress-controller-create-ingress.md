{% capture content  %}
{% navtabs ingress %}
{% navtab "EKS" %}
{% include k8s/cloud-ingress-controller-single-ingress.md provider="eks" service=include.service type=include.type %}
{% endnavtab %}
{% navtab "AKS" %}
{% include k8s/cloud-ingress-controller-single-ingress.md provider="aks" service=include.service type=include.type %}
{% endnavtab %}
{% navtab "GKE" %}
{% include k8s/cloud-ingress-controller-single-ingress.md provider="gke" service=include.service type=include.type %}
{% endnavtab %}
{% navtab "KIC" %}
{% include k8s/cloud-ingress-controller-single-ingress.md provider="kic" service=include.service type=include.type %}
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}

{% if include.indent %}
{{ content | indent }}
{% else %}
{{ content }}
{% endif %}
