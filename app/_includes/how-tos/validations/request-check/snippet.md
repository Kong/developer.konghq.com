{%- assign count = include.config.count -%}
{%- unless count %}{% assign count = 1 %}{% endunless -%}
{%- assign is_https = false -%}
{%- if include.config.mtls %}{% assign is_https = true %}{% endif -%}
{%- if include.config.insecure %}{% assign is_https = true %}{% endif -%}
{%- if include.config.url contains 'https://' %}{% assign is_https = false %}{% endif -%}

{% assign capture_size = include.config.capture | size %}
{%- capture curl_cmd %}{% if include.config.sleep %}sleep {{include.config.sleep}} && {% endif %}{% if count > 1%}for _  in {1..{{count}}}; do
{% endif %}curl {% if include.config.insecure %}-k {% endif %}{% if include.config.display_headers %}-i {% endif %}{% if include.config.method %}-X {{include.config.method}} {% endif %}{% if include.config.mtls%}-k --key key.pem --cert cert.pem {% endif %}"{% if is_https %}https://{% endif %}{{ include.config.url }}" \
     {% if include.config.output %}-o {{include.config.output}} {% endif %}--no-progress-meter --fail-with-body {% if include.config.headers %} \{%- endif -%}{% for header in include.config.headers %}
     -H "{{header}}" {%- unless forloop.last -%} \{% endunless %}{%- endfor %}{% if include.config.user %} \
     -u {{include.config.user}}{%- endif %}{% if include.config.cookie_jar %} \
     --cookie-jar {{include.config.cookie_jar}}{%- endif %}{% if include.config.cookie %} \
     --cookie {{include.config.cookie}}{%- endif %}{% if include.config.form_data %} \{% for data in include.config.form_data %}
     -F {{data[0]}}="{{data[1]}}" {% unless forloop.last -%} \{% endunless %}{%- endfor %}{% endif %}{% if include.config.form_url_encoded_data %} \{% for data in include.config.form_url_encoded_data %}
     -d "{{data[0]}}={{data[1]}}" {% unless forloop.last -%} \{% endunless %}{%- endfor %}{% endif %}{% if include.config.body_file %} \
     -F file="{{ include.config.body_file }}"{% endif %}{% if include.config.body %} \
     --json '{{ include.config.body | json_prettify: 1 | escape_env_variables | indent: 4 | strip }}'{% elsif include.config.body_cmd %} \
     --json "{{ include.config.body_cmd }}"{% endif %}{% endcapture -%}
```bash
{% if capture_size == 1 -%}
export {{ include.config.capture[0].variable }}=$({{ curl_cmd }}{% if include.config.capture[0].jq %} | jq -r "{{ include.config.capture[0].jq | strip }}"{% elsif include.config.capture[0].command %} | {{ include.config.capture[0].command | strip }}{% endif %}{% if include.config.inline_sleep %}
 sleep {{include.config.inline_sleep}}{%- endif %}
)
{%- elsif capture_size > 1 -%}
_response=$({{ curl_cmd }})
{%- else -%}
{{ curl_cmd }}{% if count > 1 %} \
; done{% endif -%}
{%- endif %}
```

{% if capture_size > 1 %}

Export the env variables:

```bash
{% for cap in include.config.capture -%}
export {{ cap.variable }}=$(echo "$_response" | {% if cap.jq %}jq -r "{{ cap.jq | strip }}"{% elsif cap.command %}{{ cap.command | strip }}{% endif %})
{% endfor -%}
```
{% endif %}

{% if include.config.message %}

You should see the following response:

```text
{{ include.config.message }}
```
{:.no-copy-code}
{% endif %}
{% if include.config.expected_headers %}{% assign header_count = include.config.expected_headers | size %}
You should see the following header{% if header_count > 1 %}s{% endif %}:

```text{% for header in include.config.expected_headers %}
{{ header }}{% endfor %}
```
{% endif %}