{% if page.auto_generated and page.major_version == nil and page.canonical? == false and page.latest? == false %}
{:.warning.!block}
> You are browsing documentation for an older version. See the [latest documentation here]({{page.canonical_url}}).
{% endif %}