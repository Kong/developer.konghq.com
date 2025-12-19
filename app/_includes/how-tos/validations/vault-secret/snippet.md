{% assign command=include.command %}
{% if include.command == empty %}
{% capture command %}docker exec {{include.container}}{% endcapture %}
{% endif %}

```bash
{{ command | liquify }} kong vault get {{include.secret}}
```