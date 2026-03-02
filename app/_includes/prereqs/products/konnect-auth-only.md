{% assign summary='Kong Konnect' %}
{%- if page.output_format == 'markdown' and page.works_on.size > 1 %}{% capture summary %}{{ summary | prepend: ": " | prepend: site.llm_copy.konnect_snippet }}{% endcapture %}{% endif -%}
{% capture details_content %}

If you don't have a Konnect account, you can get started quickly with our [onboarding wizard](https://konghq.com/products/kong-konnect/register?utm_medium=referral&utm_source=docs).

1. The following Konnect items are required to complete this tutorial:
    * Personal access token (PAT): Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.

2. Set the personal access token as an environment variable:

   ```sh
   export KONNECT_TOKEN='YOUR KONNECT TOKEN'
   ```
{% endcapture %}


{% if include.raw %}
{{ details_content }}
{% else %}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/gateway.svg' %}
{% endif %}