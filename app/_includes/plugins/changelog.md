{%- assign changelog = page.changelog -%}
{%- for version in changelog.versions %}

## {{version.number}}

**Release date:** {{version.release_date}}

{% for type in version.entries_by_type %}
###{{type[0] | capitalize | titleize}}

{% for entry in type[1] -%}
* {{entry.message | rstrip }}
{%- endfor -%}

{%- endfor -%}
{%- endfor -%}