{% assign summary='Clean up AWS resources' %}
{% capture details_content %}
If you created new AWS resources for this tutorial, make sure to delete them to avoid unnecessary charges.
{%- endcapture -%}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/aws.svg' %}