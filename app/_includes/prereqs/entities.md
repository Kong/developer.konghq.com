
{% assign summary = 'Pre-configured entities' %}
{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

{% capture details_content %}
For this tutorial, you'll need Kong Gateway entities, like services and routes, pre-configured. These entities are essential for Kong Gateway to function but installing them isn't the focus of this guide. Follow these steps to pre-configure them:   

1. Create a `prereqs.yaml` file within your `deck_files` directory, and add the following content to it:

{% capture entities %}
```yaml
{{ include.data }}
```
{: data-file="prereqs.yaml" }
{% endcapture %}
{{ entities | indent: 3 }}

1. Sync your changes in the `deck_files` directory, making sure to substitute your Konnect Personal Access Token for `konnect_token` and the control plane name for `KONNECT_CP_NAME` in the command:

   ```sh
   deck gateway sync prereqs.yaml
   ```
   {: data-deployment-topology="on-prem" }

   ```sh
   deck gateway sync prereqs.yaml --konnect-token ${{konnect_token}} --konnect-control-plane-name $KONNECT_CP_NAME
   ```
   {: data-deployment-topology="konnect" }

To learn more about entities, you can read our [entities documentation](/entities/). 
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/widgets.svg' %}
