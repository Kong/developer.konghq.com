{% if include.section == "question" %}

How can agents consume documentation published in a {{site.dev_portal}}?
{% elsif include.section == "answer" %}

When you send a request to any {{site.dev_portal}} URL using the `Accept: text/markdown header`, it will return LLM-friendly markdown instead of HTML.

For example:
```sh
curl https://portal.kongair.com/guides/prices \
  -H "Accept: text/markdown"
```

{% endif %}