{%- assign support = site.data.ai-gateway.v2.claude-code-provider-modes -%}
{% table %}
columns:
  - title: Provider mode
    key: mode
  - title: Mode switch
    key: switch
  - title: Gateway URL setting
    key: base_url
rows:
{%- for mode in support.modes %}
  - mode: "{{ mode.name }}"
    switch: "{{ mode.switch }}"
    base_url: "{{ mode.base_url }}"
{%- endfor %}
{% endtable %}

Kong last updated this list on {{ support.checked | date: "%B %-d, %Y" }}.
