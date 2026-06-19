{% if include.major_version -%}
{:.warning}
> _You are browsing documentation for an older major version - {{page.cross_major_banner_info.major_version}} - of {{page.cross_major_banner_info.product}}._
> _See the latest documentation [here]({{ include.canonical_url }})._
{% endif %}