<!--vale off-->
{% table %}
columns:
  - title: Format
    key: format
  - title: Capability
    key: capability
  - title: Supported providers
    key: providers
  - title: Notes
    key: notes
rows:
{% for entry in site.data.ai-gateway.v2.format-support.formats %}
{% for row in entry.capabilities %}
  - format: "`{{ entry.format }}`"
    capability: "{{ row.capability }}"
    providers: "{{ row.providers }}"
    notes: "{{ row.notes }}"
{% endfor %}
{% endfor %}
{% endtable %}
<!--vale on-->
