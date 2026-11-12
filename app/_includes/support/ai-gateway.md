<!-- vale off-->
{% table %}
columns:
  - title: OS
    key: os
  - title: Version
    key: version
  - title: ARM support
    key: arm
  - title: FIPS 140-3
    key: fips
  - title: EOL
    key: eol
rows:
{% for d in include.release.distributions %}
  - os: {{ d.os }}
    version: "{{ d.version }}"
    arm: {{ d.arm }}
    fips: {{ d.fips }}
    eol: "{{ d.eol | default: include.release.eol }}"
{% endfor %}
{% endtable %}
<!-- vale on-->
