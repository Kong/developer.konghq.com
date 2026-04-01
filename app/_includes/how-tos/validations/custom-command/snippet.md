{%- assign command = include.config.command -%}
{%- assign expected = include.config.expected -%}

```bash
{{ command | strip }}
```

{%- unless include.config.render_output == false -%}
{%- if expected.stdout -%}
You should see the following content on `stdout`:

```bash
{{ expected.stdout }}
```
{% endif %}

{%- if expected.stderr -%}
You should{% if expected.stdout %} also{% endif %} see the following content on `stderr`:

```bash
{{ expected.stderr }}
```
{% endif %}

Check the return code of the command{% if expected.return_code == 0 %} to make sure it completed successfully{% endif %}:

{%- if expected.return_code %}
```bash
if [[ $? -ne {{ expected.return_code }} ]]; then
  echo "Did not receive the expected return code"
fi
```
{% endif %}
{% endunless %}