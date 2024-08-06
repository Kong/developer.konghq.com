<div class="flex flex-col space-y-4">
  <div class="grid grid-cols-2 gap-4">
    {% for header in include.config.headers %}
      <div class="font-bold">{{ header }}</div>
    {% endfor %}
  </div>
  {% for item in include.config.items %}
    <div class="grid grid-cols-2 gap-4">
      <div>{{ item.text | markdownify }}</div>
      <div>
        {% case item.action.type %}
          {% when "entity_card" %}
            <div class="entity-card">
              Entity: {{ item.action.config.entity }}
            </div>
          {% when "command" %}
            <div class="command">
              <pre>{{ item.action.config.cmd }} {{ item.action.config.args | join: " " }}</pre>
            </div>
          {% when "formula" %}
            <div class="formula">
              <div><strong>{{ item.action.config.name }}</strong>: {{ item.action.config.desc }}</div>
              <pre>{{ item.action.config.install }}</pre>
            </div>
          {% when "entity_example" %}
            <div class="entity-example">
              <div><strong>Type:</strong> {{ item.action.config.type }}</div>
              <div><strong>Formats:</strong> {{ item.action.config.formats | join: ", " }}</div>
              <div><strong>Data:</strong></div>
              <pre>{{ item.action.config.data | jsonify }}</pre>
            </div>
          {% else %}
            <div>Unknown action type</div>
        {% endcase %}
      </div>
    </div>
  {% endfor %}
</div>
