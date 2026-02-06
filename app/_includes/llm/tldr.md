{% if page.tldr %}
## TL;DR

**{{page.tldr.q | liquify }}**
{{ page.tldr.a | liquify }}
{% endif %}