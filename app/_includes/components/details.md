{% for i in (1..heading_level) %}#{% endfor %} {{config.summary | liquify}}

{{config.content | liquify }}