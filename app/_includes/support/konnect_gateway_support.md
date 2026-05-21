{% assign versions = site.data.support.gateway | where: "konnect", true %}

{% table %}
columns:
  - title: Kong Gateway version
    key: version
  - title: Beginning with version
    key: beginning
  - title: End of support
    key: eol
rows:
{% for version in versions %}
  - version: "{{version.release}}.x{% if version.lts %} (LTS){% endif %}"
    beginning: "{{version.beginning}}"
    eol: "{{version.eol}}"
{% endfor %}
{% endtable %}
