{% assign text_size="xl" -%}
{% if include.config.type == "h2" %}{% assign text_size="2xl" %}{% endif -%}
{% if include.config.type == "h1" %}{% assign text_size="3xl" %}{% endif -%}
<{{ include.config.type }} class="text-{{ text_size }} self-{{ include.config.align }}">{{ include.config.text }}</{{ include.config.type }}>
