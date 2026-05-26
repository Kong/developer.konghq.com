{% if include.section == "question" %}

Can I add GraphQL endpoints to an API or API package, or set GraphQL-specific rate limits, in {{site.dev_portal}}?

{% elsif include.section == "answer" %}

No. {{site.dev_portal}} doesn't support GraphQL. The spec renderer and application registration flows are built for OpenAPI and AsyncAPI specs, and there's no GraphQL-specific rate limiting available through {{site.dev_portal}}.

{% endif %}
