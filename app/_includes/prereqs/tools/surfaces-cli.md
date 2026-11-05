{% capture summary %}
{{site.surfaces_cli}}
{% endcapture %}

{% capture details_content %}
This tutorial uses [{{site.surfaces_cli}}](/surfaces-cli/).

1. Install {{site.surfaces_cli}} from [developer.konghq.com/surfaces-cli](/surfaces-cli/#install-surfaces-cli).
1. Verify the installation:

   ```sh
   surfaces-cli version
   ```
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/code.svg' %}
