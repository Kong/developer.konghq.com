{% assign summary='Create a KonnectExtension resource' %}
{%- if page.output_format == 'markdown' and page.works_on.size > 1 %}{% capture summary %}{{ summary | prepend: ": " | prepend: site.llm_copy.konnect_snippet }}{% endcapture %}{% endif -%}
{% capture details_content %}
```bash
echo '
kind: KonnectExtension
apiVersion: konnect.konghq.com/{{ site.operator_konnectextension_api_version }}
metadata:
  name: my-konnect-config
  namespace: kong
spec:
  clientAuth:
    certificateSecret:
      provisioning: Automatic
  konnect:
    controlPlane:
      ref:
        type: konnectNamespacedRef
        konnectNamespacedRef:
          name: gateway-control-plane' | kubectl apply -f -
```
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/kubernetes.svg' %}