{% if page.overview? -%}
{%- if page.ai_gateway_url %}
{:.warning.-my-4}
> You're viewing the AI Gateway 1.0 version of this plugin. Looking for the AI Gateway 2.0 policy? [Go to the AI Gateway 2.0 version]({{page.ai_gateway_url}}).
{% endif %}{%- if page.premium_partner and page.third_party %}

{:.decorative.w-full.-my-4}
> **Premium Partner:** This plugin is developed, tested, and maintained by [{{site.data.plugin_publishers[page.publisher].name}}]({{page.support_url}}).

{% elsif page.third_party %}
{:.success.w-full.-my-4}
> **Third Party:** This plugin is developed, tested, and maintained by [{{site.data.plugin_publishers[page.publisher].name}}]({{page.support_url}}).

{%- endif %}
{%- if page.tier and page.tier == 'ai_gateway_enterprise' %}
{:.ai.w-full.-my-4}
> **AI Gateway Enterprise:** This plugin is only available as part of our AI Gateway Enterprise offering. 
{% endif %}{% endif %}