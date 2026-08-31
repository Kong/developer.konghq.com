{% capture summary %}
kongctl &nbsp; {% new_in site.data.kongctl_latest.version %}
{% endcapture %}

{% capture details_content %}
This tutorial uses [kongctl](/kongctl/) to manage {{site.konnect_short_name}} resources programmatically.
We recommend keeping kongctl up to date with the latest version ({{site.data.kongctl_latest.version}}).

1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
1. Verify the installation:

   ```sh
   kongctl version
   ```
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/code.svg' %}
