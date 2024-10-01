
{% assign summary = 'Pre-configured entities' %}
{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

{% capture details_content %}
For this tutorial, you'll need {{site.base_gateway}} entities, like Gateway Services and Routes, pre-configured. These entities are essential for {{site.base_gateway}} to function but installing them isn't the focus of this guide. Follow these steps to pre-configure them:

1. Create a `prereqs.yaml` file within your `deck_files` directory, and add the following content to it:

{% capture entities %}
```yaml
echo '
{{ include.data }}
' | kongctl apply gateway -
```
{: data-file="prereqs.yaml" }
{% endcapture %}
{{ entities | indent: 3 }}

To learn more about entities, you can read our [entities documentation](/entities/). 
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/widgets.svg' %}
