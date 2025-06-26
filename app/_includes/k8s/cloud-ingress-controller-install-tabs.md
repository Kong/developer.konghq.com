{% capture content  %}
{% navtabs ingress %}
{% navtab "EKS" %}
{% include k8s/cloud/eks/install.md service=include.service release=include.release %}
{% endnavtab %}
{% navtab "AKS" %}
{% include k8s/cloud/aks/install.md service=include.service release=include.release %}
{% endnavtab %}
{% navtab "GKE" %}
{% include k8s/cloud/gke/install.md service=include.service release=include.release %}
{% endnavtab %}
{% navtab "KIC" %}
{% include k8s/cloud/kic/install.md service=include.service release=include.release %}
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}

{% if include.indent %}
{{ content | indent }}
{% else %}
{{ content }}
{% endif %}
