{%- assign support = site.data.ai-gateway.v2.claude-code-provider-modes -%}
{% table %}
columns:
  - title: Provider mode
    key: mode
  - title: Mode switch
    key: switch
  - title: Gateway URL setting
    key: url
  - title: Cloud sign-in skip switch
    key: skip_auth
  - title: Other settings
    key: other
rows:
{%- for mode in support.modes %}
  - mode: "{{ mode.name }}"
    switch: "{{ mode.switch }}"
    url: "{{ mode.url }}"
    skip_auth: "{{ mode.skip_auth }}"
    other: "{{ mode.other }}"
{%- endfor %}
{% endtable %}
