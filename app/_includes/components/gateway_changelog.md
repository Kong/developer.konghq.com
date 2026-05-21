{% for version in changelog.versions %}

## {{version.number}}

**Release date:** {{version.release_date}}

{% for type in version.entries_by_type %}

### {{type[0] | capitalize | titleize}}

{% for entries_by_scope in type[1].by_scope %}

#### {{entries_by_scope[0]}}

{% if entries_by_scope[0] == 'Plugin' -%}
{%- for plugin in entries_by_scope[1] -%}
{%- if plugin[0] == '_no_link_' %}
{%- for entry in plugin[1] %}
* {{entry.message | rstrip}}{%-endfor%}
{%- else -%}
* {{plugin[0]}}
{%- for entry in plugin[1] %}  * {{entry.message |rstrip}}
{%- endfor -%}
{%- endif -%}
{%- endfor -%}
{%- else -%}
{%- for entry in entries_by_scope[1] -%}
* {{entry.message | rstrip}}
{%- endfor -%}
{%- endif -%}
{%- endfor -%}
{%- endfor -%}
{%- endfor -%}