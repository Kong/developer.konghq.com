<div class="flex flex-col gap-5 p-6 rounded-md border border-primary/5 bg-secondary shadow-primary">
    {% if include.config.icon %}
        <img src="{{ include.config.icon}}" class="w-8 h-8"/>
    {% endif %}

    <h3>{{ include.config.title}}</h3>

    <div class="flex flex-col flex-grow">
        {{ include.config.description | markdownify }}
    </div>

    {% if include.config.cta %}
    <div class="flex">
        {% include landing_pages/cta.md config=include.config.cta %}
    </div>
{% endif %}
</div>