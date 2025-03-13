{% assign plugin_name = include.config.plugin %}

{% assign plugins_list = site.data.kong_plugins %}

{% assign plugin = plugins_list | where_exp: "plugin", "plugin.name contains plugin_name" | first %}

{% include card.html title=plugin.name description=plugin.description cta_url=plugin.url %}