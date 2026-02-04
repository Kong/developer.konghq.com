{%- assign count = include.count -%}
{%- unless count %}{% assign count = 1 %}{% endunless -%}
{%- assign is_https = false -%}
{%- if include.mtls %}{% assign is_https = true %}{% endif -%}
{%- if include.insecure %}{% assign is_https = true %}{% endif -%}
{%- if include.url contains 'https://' %}{% assign is_https = false %}{% endif -%}

```bash
{% if include.capture -%}
{{include.capture}}=$({% endif %}{% if include.sleep %}sleep {{include.sleep}} && {% endif %}{% if count > 1%}for _  in {1..{{count}}}; do
{% endif %}curl {% if include.insecure %}-k {% endif %}{% if include.display_headers %}-i {% endif %}{% if include.method %}-X {{include.method}} {% endif %}{% if include.mtls%}-k --key key.pem --cert cert.pem {% endif %}"{% if is_https %}https://{% endif %}{{ include.url }}" \
     {% if include.output %}-o {{include.output}} {% endif %}--no-progress-meter --fail-with-body {% if include.headers %} \{%- endif -%}{% for header in include.headers %}
     -H "{{header}}" {%- unless forloop.last -%} \{% endunless %}{%- endfor %}{% if include.user %} \
     -u {{include.user}}{%- endif %}{% if include.cookie_jar %} \
     --cookie-jar {{include.cookie_jar}}{%- endif %}{% if include.cookie %} \
     --cookie {{include.cookie}}{%- endif %}{% if include.form_data %} \{% for data in include.form_data %}
     -F {{data[0]}}="{{data[1]}}" {% unless forloop.last -%} \{% endunless %}{%- endfor %}{% endif %}{% if include.body %} \
     --json '{{ include.body | json_prettify: 1 | escape_env_variables | indent: 4 | strip }}'{% elsif include.body_cmd %} \
     --json "{{ include.body_cmd }}"{% endif %}{% if include.jq %} | jq -r "{{ include.jq | strip }}"{% endif %}{% if include.capture -%}
     {%- if include.inline_sleep %}
  sleep {{include.inline_sleep}}{%- endif %}
){% endif -%}
{% if count > 1 %}; done{% endif %}
```

{% if include.message %}
You should see the following response:

```text
{{ include.message }}
```
{:.no-copy-code}
{% endif %}


{% if include.expected_headers %}
{% assign header_count = include.expected_headers | size %}
You should see the following header{% if header_count > 1 %}s{% endif %}:

```text{% for header in include.expected_headers %}
{{ header }}{% endfor %}
```
{% endif %}
