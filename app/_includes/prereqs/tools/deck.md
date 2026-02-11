{% capture summary %}decK &nbsp; {% new_in 1.43 %}{% endcapture %}
{% capture details_content %}
decK is a CLI tool for managing {{site.base_gateway}} declaratively with state files.
To complete this tutorial, install [decK](/deck/) **version 1.43** or later.

This guide uses `deck gateway apply`, which directly applies entity configuration to your Gateway instance.
We recommend upgrading your decK installation to take advantage of this tool.

You can check your current decK version with `deck version`.
{% endcapture %}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/code.svg' %}