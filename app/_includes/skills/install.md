{% if site.data.skill_install_tabs.size > 0 %}
{% navtabs "tools" heading_level=2 %}
{% for tab in site.data.skill_install_tabs %}
{% navtab {{ tab.title }} slug={{ tab.slug }} icon={{ tab.icon }} %}
{% if include.extended %}{{ tab.extended_content }}{% else %}
{{ tab.content }}
Visit the [Install page](/skills/install/?tab={{tab.slug}}) for detailed instructions.{% endif %}
{% endnavtab %}
{% endfor %}
{% endnavtabs %}
{% endif %}
