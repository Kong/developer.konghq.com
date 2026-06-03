{% assign deck_latest = site.data.tools.deck.releases | first %}
{% capture summary %}decK &nbsp; {% new_in deck_latest.version %}{% endcapture %}
{% capture details_content %}

To complete this tutorial, install [decK](/deck/). We recommend keeping decK up to date with the latest version ({{deck_latest.version}}).

decK is a CLI tool for managing {{site.base_gateway}} declaratively with state files.
This guide uses `deck gateway apply`, which directly applies entity configuration to your Gateway instance.

You can check your current decK version with `deck version`.
{% endcapture %}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/code.svg' %}