{% assign summary = "Create a KIC Control Plane" %}
{%- if include.config.gateway_api_optional == true -%}
{%- assign summary = summary | append: " (Optional)" -%}
{%- endif -%}
{%- assign icon_url = "/assets/icons/admin-api.svg" -%}
{%- capture details_content -%}
{% include k8s/kic-konnect-install.md skip_values_file=true is_prereq=true %}
{%- endcapture -%}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url=icon_url %}