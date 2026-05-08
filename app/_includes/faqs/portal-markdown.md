{% if include.section == "question" %}

How can agents consume documentation published in a {{site.dev_portal}}?
{% elsif include.section == "answer" %}

When you send a request to any {{site.dev_portal}} URL using the `Accept: text/markdown` header or adding `.md` to the URL (for example, `/guides/flights` as `/guides/flights.md`), it will return LLM-friendly markdown instead of HTML.

For example:
```sh
curl https://portal.kongair.dev/guides/flights \
  -H "Accept: text/markdown"
```

{% endif %}
