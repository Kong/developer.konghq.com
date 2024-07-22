{% assign entity_id = include.config.entity %}

{% assign entities_list = site.kong_entities %}
{% assign entity = entities_list | where_exp: "entity", "entity.entities contains entity_id" | first %}

<div class="rounded p-2 border-2 border-gray-200 flex flex-col">
    <div>
        <h3>{{ entity.title }}</h3>
        <p>{{ entity.description }}</p>
    </div>
    <a href="{{ entity.url }}" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded self-end">
    See reference
    </a>
</div>