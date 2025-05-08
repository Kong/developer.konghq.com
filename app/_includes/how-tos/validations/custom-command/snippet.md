{% assign command = include.config.command %}
{% assign expected = include.config.expected %}

```bash
{{ command | strip }}
```

{% if expected.stdout %}
You should see the following content on `stdout`:

```bash
{{ expected.stdout }}
```
{% endif %}

{% if expected.stderr %}
You should{% if expected.stdout %} also{% endif %} see the following content on `stderr`:

```bash
{{ expected.stderr }}
```
{% endif %}