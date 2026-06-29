{% if page.plugin? and page.overview? %}{% assign product = page.products | first %}{% if product and product == 'gateway' %}{% include plugins/banners.md %}{% endif %}{% endif %}

{% include banners/cross_major_banner.md major_version=page.major_version  canonical_url=page.canonical_url %}
{% include banners/auto_generated_reference.md %}