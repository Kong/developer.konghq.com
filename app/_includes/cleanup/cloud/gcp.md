
{% assign summary='Cleanup Google Cloud Resources' %}
{% capture details_content %}
If you created new Google Cloud resources for this tutorial, make sure to delete them to avoid unnecessary charges.
{%- endcapture -%}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/google-cloud.svg' %}