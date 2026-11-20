{%- assign provider_modes = site.data.ai-gateway.v2.claude-code-provider-modes -%}
{% table %}
columns:
  - title: Provider mode
    key: mode
  - title: Mode switch
    key: switch
  - title: Gateway URL setting
    key: url
  - title: Cloud sign-in skip switch
    key: skip
  - title: Other settings
    key: other
rows:
{%- for mode in provider_modes.modes %}
  - mode: "{{ mode.name }}"
    switch: "{{ mode.switch }}"
    url: "{{ mode.url }}"
    skip: "{{ mode.skip }}"
    other: "{{ mode.other }}"
{%- endfor %}
{% endtable %}
