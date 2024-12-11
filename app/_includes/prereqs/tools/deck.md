{% assign summary = 'decK' %}

{% capture details_content %}
  decK is a CLI tool for managing {{site.base_gateway}} declaratively with state files.
  To complete this tutorial you will first need to:
  1. Install [decK](/deck/).
  1. Create a `deck_files` directory and a `kong.yaml` file in the directory:

      ```bash
      mkdir deck_files  && touch deck_files/kong.yaml
      ```
      {: data-test-prereqs="block" }


{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/code.svg' %}