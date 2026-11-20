{%- assign support = site.data.ai-gateway.v2.claude-code-provider-modes -%}
{% table %}
columns:
  - title: Provider mode
    key: mode
  - title: Mode switch
    key: switch
  - title: Gateway URL setting
    key: url
rows:
{%- for mode in support.modes %}
  - mode: "{{ mode.name }}"
    switch: "{{ mode.switch }}"
    url: "{{ mode.url }}"
{%- endfor %}
{% endtable %}
