{% if page.tldr %}
## TL;DR
{{ page.tldr.a | liquify | markdownify }}
{% endif %}