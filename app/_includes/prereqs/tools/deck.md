{% assign summary = 'decK' %}

{% capture details_content %}
  decK is a CLI tool for managing Kong Gateway declaratively with state files.
  To complete this tutorial you will first need to:
  1. Install [decK](/deck/)
  2. Create a `kong.yaml` file within your working directory.

  decK enables a simpler configuration and troubleshooting process allowing you to focus on the tutorial and not the tools.
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content %}