{% assign summary = "Create a KIC Control Plane" %}
{%- if page.output_format == 'markdown' and page.works_on.size > 1 %}{% capture summary %}{{ summary | prepend: ": " | prepend: site.llm_copy.konnect_snippet }}{% endcapture %}{% endif -%}
{%- if include.config.gateway_api_optional == true -%}
{%- assign summary = summary | append: " (Optional)" -%}
{%- endif -%}
{%- assign icon_url = "/assets/icons/admin-api.svg" -%}
{%- capture details_content -%}
{% include k8s/kic-konnect-install.md skip_values_file=true is_prereq=true %}
{%- endcapture -%}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url=icon_url %}