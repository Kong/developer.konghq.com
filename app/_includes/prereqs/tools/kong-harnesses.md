{% capture summary %}
kong-harnesses
{% endcapture %}

{% capture details_content %}
This tutorial uses [kong-harnesses](/kong-harnesses/) to sign in developers and configure their coding agents.

1. Install **kong-harnesses** with the steps in [Install kong-harnesses](/kong-harnesses/#install-kong-harnesses).
1. Verify the installation:

   ```sh
   kong-harnesses version
   ```

If the shell can't find `kong-harnesses`, open a new terminal.
On macOS and Linux, export the variables from the earlier prerequisites again.
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/code.svg' %}
