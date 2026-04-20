{% if site.data.skill_install_tabs.size > 0 %}
{% navtabs "tools" heading_level=2 %}
{% for tab in site.data.skill_install_tabs %}
{% navtab {{ tab.title }} slug={{ tab.slug }} icon={{ tab.icon }} %}
{{ tab.content }}
{% endnavtab %}
{% endfor %}
{% endnavtabs %}
{% endif %}
