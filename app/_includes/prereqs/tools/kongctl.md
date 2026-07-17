{% capture summary %}
kongctl &nbsp; {% new_in site.data.kongctl_latest.version %}
{% endcapture %}

{% capture details_content %}
{% assign product=page.products[0] %}
{% if product == 'ai-gateway' %}
This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.
We recommend keeping kongctl up to date with the latest version ({{site.data.kongctl_latest.version}}).

1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
1. Verify the installation:

   ```sh
   kongctl version
   ```

If you're using an existing {{site.ai_gateway}} instead of the quickstart script, adopt it into a kongctl namespace so the apply command later in this tutorial can manage it:

```sh
kongctl adopt ai-gateway "$AI_GATEWAY_ID" \
    --namespace ai-gateway-get-started \
    --pat "$KONNECT_TOKEN"
```
{% else %}
  kongctl is a CLI tool for managing {{site.konnect_short_name}} resources programmatically. To complete this tutorial, 
  install [kongctl](/kongctl/).
{% endif %}
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/code.svg' %}
