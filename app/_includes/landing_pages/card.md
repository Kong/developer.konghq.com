<div class="rounded p-2 border-2 border-gray-200 flex flex-col">
<div>
<h3>{{ include.config.title}} <img src="{{ include.config.icon}}" class="w-5 h-5 inline"></h3>
<p>{{ include.config.description}}</p>
</div>
{% if include.config.cta %}
{% include landing_pages/cta.md config=include.config.cta %}
{% endif %}
</div>