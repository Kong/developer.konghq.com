{% if include.canonical_url and include.major_version -%}
{% if include.canonical_url == include.url %}
{:.warning}
> This content is not available in the latest version.
{% else %}
{:.warning}
> _You are browsing documentation for an older version._
> _See the latest documentation [here]({{ include.canonical_url }})._
{% endif %}{% endif %}
