<div class="rounded p-2 border-2 border-gray-200 flex flex-col">
<div>
<h3>{{ include.config.title}}</h3>
<p>{{ include.config.description}}</p>
<a href="{{ include.config.icon}}"><img src="{{ include.config.icon}}"></a>
</div>
{% if include.config.cta %}
{% include landing_pages/cta.md config=include.config.cta %}
{% endif %}
</div>