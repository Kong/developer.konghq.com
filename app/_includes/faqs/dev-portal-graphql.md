{% if include.section == "question" %}

Does {{site.dev_portal}} support adding GraphQL endpoints to an API or API package, or setting GraphQL-specific rate limits?

{% elsif include.section == "answer" %}

No. {{site.dev_portal}} doesn't support GraphQL. The spec renderer and application registration flows are built for OpenAPI and AsyncAPI specs, and there's no GraphQL-specific rate limiting available through {{site.dev_portal}}.

{% endif %}
