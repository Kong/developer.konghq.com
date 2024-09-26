
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

1. Sync your changes.

   ```sh
   deck gateway sync deck_files
   ```
   {: data-deployment-topology="on-prem" }


   <div class="flex flex-col gap-2" data-deployment-topology="konnect" markdown="1">
    Make sure to substitute your Konnect Personal Access Token for `konnect_token` and the control plane name for `KONNECT_CP_NAME` in the command:
   ```sh
   deck gateway sync deck_files --konnect-token ${{konnect_token}} --konnect-control-plane-name $KONNECT_CP_NAME
   ```
   </div>

To learn more about entities, you can read our [entities documentation](/entities/). 
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/widgets.svg' %}
