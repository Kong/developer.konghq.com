{% if page.plugin? and page.overview? %}{% assign product = page.products | first %}{% if product and product == 'gateway' %}{% include plugins/banners.md %}{% endif %}{% endif %}

{% include banners/auto_generated_reference.md %}