{% assign summary = 'Required entities' %}
{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

{% capture details_content %}
For this tutorial, you'll need {{site.base_gateway}} entities, like Gateway Services and Routes, pre-configured. These entities are essential for {{site.base_gateway}} to function but installing them isn't the focus of this guide. Follow these steps to pre-configure them:

1. Run the following command:

{% capture entities %}
```yaml
echo '
{{ include.data }}
' | deck gateway apply -
```
{: data-test-prereqs="block" }
{% endcapture %}
{{ entities | indent: 3 }}

To learn more about entities, you can read our [entities documentation](/gateway/entities/).
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/widgets.svg' %}
