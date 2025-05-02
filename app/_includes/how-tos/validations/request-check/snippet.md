{% assign count = include.count %}
{% unless count %}{% assign count = 1 %}{% endunless %}

{% assign is_https = false %}
{% if include.mtls %}{% assign is_https = true %}{% endif %}
{% if include.insecure %}{% assign is_https = true %}{% endif %}
```bash
{% if include.capture -%}
{{include.capture}}=$({% endif %}{% if include.sleep %}sleep {{include.sleep}} && {% endif %}{% for i in (1..count) %}curl {% if include.insecure %}-k {% endif %}{% if include.display_headers %}-i {% endif %}{% if include.method %}-X {{include.method}} {% endif %}{% if include.mtls%}-k --key key.pem --cert cert.pem {% endif %}"{% if is_https %}https://{% endif %}{{ include.url }}"{% if include.headers %} \{%- endif -%}{% for header in include.headers %}
     -H "{{header}}" {%- unless forloop.last -%} \{% endunless %}{%- endfor %}{% if include.user %} \
     -u {{include.user}}{%- endif %}{% if include.cookie_jar %} \
     --cookie-jar {{include.cookie_jar}}{%- endif %}{% if include.cookie %} \
     --cookie {{include.cookie}}{%- endif %}{% if include.body %} \
     --json '{{ include.body | json_prettify: 1 | escape_env_variables | indent: 4 | strip }}'{% endif %}{% if include.jq %} | jq {{ include.jq }}{% endif %}{% if include.capture -%}){% endif %}
{% endfor -%}
```

{% if include.message %}
You should see the following response:

```text
{{ include.message }}
```
{% endif %}