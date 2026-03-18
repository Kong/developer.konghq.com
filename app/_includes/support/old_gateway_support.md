{% assign today = 'now' | date: '%s' -%}
{%- assign versions = "" | split: "" -%}
{%- for version in site.data.support.gateway -%}
  {%- assign timestamp = version.eol | date: '%s' -%}
  {%- if timestamp < today -%}
    {%- assign versions = versions | push: version -%}
  {%- endif -%}
{%- endfor -%}

{% table %}
columns:
  - title: Version
    key: version
  - title: Released Date
    key: release_date
  - title: End of Full Support
    key: eol
  - title: End of Sunset Support
    key: sunset
rows:
{% for version in versions %}
  - version: "{{version.release}}{% unless version.release[0] != 0 %}.x.x{% endunless %}"
    release_date: "{{version.release_date}}"
    eol: "{{version.eol}}"
    sunset: "{{version.sunset}}"
{% endfor %}
{% endtable %}