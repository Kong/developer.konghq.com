{% assign config = include.config %}
{% assign sections = config.sections %}
{% assign section_a = sections[0] %}
{% assign section_b = sections[1] %}
{% assign storage_key = config.storage_key | default: "lp-toggle" %}

<div class="lp-toggle-wrapper">
  <div class="switch" data-lp-toggle="{{ storage_key }}">
    <div class="switch__options">
      <label for="{{ storage_key }}-{{ section_a.id }}" class="switch__option-label">{{ section_a.label }}</label>
      <div class="switch__wrapper">
        <input type="radio" id="{{ storage_key }}-{{ section_a.id }}" name="{{ storage_key }}-view" value="{{ section_a.id }}" class="switch__input">
        <input type="radio" id="{{ storage_key }}-{{ section_b.id }}" name="{{ storage_key }}-view" value="{{ section_b.id }}" class="switch__input">
        <span class="switch__slider"></span>
      </div>
      <label for="{{ storage_key }}-{{ section_b.id }}" class="switch__option-label">{{ section_b.label }}</label>
    </div>
  </div>

  {% for section in sections %}
  <div data-lp-section="{{ section.id }}">
    <div class="grid grid-cols-1 lg:grid-cols-{{ section.column_count | default: 3 }} gap-8 mt-8">
      {% for card in section.cards %}
      {% include card.html title=card.title description=card.description cta_url=card.cta.url cta_text=card.cta.text %}
      {% endfor %}
    </div>
  </div>
  {% endfor %}
</div>

<script>
(function () {
  document.querySelectorAll("[data-lp-toggle]").forEach(function (switchEl) {
    if (switchEl.dataset.lpToggleInit) return;
    switchEl.dataset.lpToggleInit = "true";

    var storageKey = "lp-toggle-" + switchEl.dataset.lpToggle;
    var wrapper = switchEl.closest(".lp-toggle-wrapper");
    var inputs = switchEl.querySelectorAll(".switch__input");
    var sections = wrapper.querySelectorAll("[data-lp-section]");
    var slider = switchEl.querySelector(".switch__slider");

    function showSection(id) {
      sections.forEach(function (s) {
        s.style.display = s.dataset.lpSection === id ? "" : "none";
      });
      inputs.forEach(function (input) {
        input.checked = input.value === id;
      });
      try {
        localStorage.setItem(storageKey, id);
      } catch (e) {}
    }

    var initial = inputs[0] ? inputs[0].value : null;
    try {
      var stored = localStorage.getItem(storageKey);
      if (stored) initial = stored;
    } catch (e) {}
    if (initial) showSection(initial);

    inputs.forEach(function (input) {
      input.addEventListener("change", function (e) {
        showSection(e.target.value);
      });
    });

    if (slider) {
      slider.addEventListener("click", function () {
        var unchecked = Array.from(inputs).find(function (i) {
          return !i.checked;
        });
        if (unchecked) {
          unchecked.checked = true;
          unchecked.dispatchEvent(new Event("change", { bubbles: true }));
        }
      });
    }
  });
})();
</script>
