{% assign summary='Cleanup Azure Resources' %}
{% capture details_content %}
If you created new Azure resources for this tutorial, make sure to delete them to avoid unnecessary charges.
{%- endcapture -%}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/azure.svg' %}