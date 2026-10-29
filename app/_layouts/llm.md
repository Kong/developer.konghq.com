{%- if page.content_type == 'landing_page' -%}
{% include llm/frontmatter.md %}
{% include llm/banners.md %}
{% include llm/landing_page.md %}
{%- else -%}
{% include llm/frontmatter.md %}
# {{page.llm_title | liquify }}

{% include llm/banners.md %}
{% include llm/tldr.md %}
{% include llm/series.md %}
{% include llm/prereqs.md %}
{{ content }}
{% if page.url contains '/ai-gateway/entities/' and page.works_on contains 'on-prem' %}
{% include ai-gateway/on-prem-config.md %}
{% endif %}
{% include llm/cleanup.md %}
{%- if page.faqs %}
## FAQs
{% faqs %}
{%- endif -%}
{% if page.related_resources %}
## Related Resources
{% related_resources %}
{%- endif -%}
{%- if page.next_steps %}
## Next Steps
{% next_steps %}
{%- endif -%}
{%- endif -%}