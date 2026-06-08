{% comment %}
  Renders a product/persona toggle for the learning paths landing page.
  Card sections are built from site.pages at build time, so no manual
  updates are needed when new learning paths are added.
{% endcomment %}

{% assign lp_index_pages = site.pages | where: "layout", "learning-path-index" %}
{% assign product_pages = lp_index_pages | where_exp: "p", "p.product != nil and p.product != empty" %}
{% assign persona_pages = lp_index_pages | where_exp: "p", "p.persona != nil and p.persona != empty" %}

{% assign storage_key = "learning-paths-view" %}

<div class="lp-toggle-wrapper">
  <div class="switch" data-lp-toggle="{{ storage_key }}">
    <div class="switch__options">
      <label for="{{ storage_key }}-product" class="switch__option-label">By Product</label>
      <div class="switch__wrapper">
        <input type="radio" id="{{ storage_key }}-product" name="{{ storage_key }}-view" value="product" class="switch__input">
        <input type="radio" id="{{ storage_key }}-persona" name="{{ storage_key }}-view" value="persona" class="switch__input">
        <span class="switch__slider"></span>
      </div>
      <label for="{{ storage_key }}-persona" class="switch__option-label">By Persona</label>
    </div>
  </div>

  <div data-lp-section="product">
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mt-8">
      {% for p in product_pages %}
        {% assign product = site.data.products[p.product] %}
        {% assign path_titles = p.learning_paths | map: "title" | join: ", " %}
        {% include card.html title=product.name description=path_titles cta_url=p.url cta_text="View paths" %}
      {% endfor %}
    </div>
  </div>

  <div data-lp-section="persona">
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-8">
      {% for p in persona_pages %}
        {% assign persona = site.data.personas | where: "id", p.persona | first %}
        {% include card.html title=persona.name description=persona.description cta_url=p.url cta_text="View paths" %}
      {% endfor %}
    </div>
  </div>
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
