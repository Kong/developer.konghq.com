class SkillsIndex {
  constructor() {
    this.searchInput = document.getElementById("skills-search");
    this.skillsGrid = document.getElementById("skills-grid");
    this.emptyState = document.getElementById("skills-empty");
    this.clearButton = document.getElementById("skills-clear-filters");
    this.filterContainers = Array.from(
      document.querySelectorAll(".dropdown-container[data-skills-filter]"),
    );

    if (!this.searchInput || !this.skillsGrid || !this.emptyState) return;

    this.cards = Array.from(this.skillsGrid.querySelectorAll('[data-card="skill"]'));
    this.cardSearchStrings = new Map(
      this.cards.map((card) => [
        card,
        [card.dataset.title, card.dataset.description, card.dataset.tags, card.dataset.plugin, card.dataset.products, card.dataset.category]
          .filter(Boolean)
          .join(" ")
          .toLowerCase(),
      ])
    );
    this.searchQuery = "";

    this.addEventListeners();
    this.preventCopyNavigation();
    this.readURL();
    this.filterCards();
  }

  setFilterValue(container, value) {
    container.dataset.skillsFilterValue = value;
    const label = container.querySelector(".dropdown-label");

    container.querySelectorAll('[role="menuitem"]').forEach((item) => {
      const isSelected = item.dataset.value === value;
      item.querySelector("svg")?.classList.toggle("invisible", !isSelected);
      if (isSelected && label) label.textContent = item.childNodes[0].textContent.trim();
    });
  }

  preventCopyNavigation() {
    this.skillsGrid.addEventListener("click", (e) => {
      if (e.target.closest("clipboard-copy")) {
        e.preventDefault();
      }
    });
  }

  addEventListeners() {
    this.searchInput.addEventListener("input", () => {
      this.searchQuery = this.searchInput.value;
      this.filterCards();
      this.updateURL();
    });

    this.filterContainers.forEach((container) => {
      container.querySelectorAll('[role="menuitem"]').forEach((item) => {
        item.addEventListener("click", () => {
          this.setFilterValue(container, item.dataset.value || "");
          this.filterCards();
          this.updateURL();
        });
      });
    });

    this.clearButton?.addEventListener("click", () => {
      this.searchQuery = "";
      this.searchInput.value = "";
      this.filterContainers.forEach((container) => this.setFilterValue(container, ""));
      this.filterCards();
      this.updateURL();
    });
  }

  filterCards() {
    const query = this.searchQuery.toLowerCase().trim();
    const filters = Object.fromEntries(
      this.filterContainers.map((c) => [c.dataset.skillsFilter, c.dataset.skillsFilterValue || ""])
    );
    const activeProduct = filters.product || "";
    const activeCategory = filters.category || "";
    let count = 0;

    this.cards.forEach((card) => {
      const matchesSearch = !query || this.cardSearchStrings.get(card).includes(query);
      const productValues = (card.dataset.productValues || "").split("|").filter(Boolean);
      const matchesProduct = !activeProduct || productValues.includes(activeProduct);
      const matchesCategory = !activeCategory || card.dataset.categoryValue === activeCategory;
      const visible = matchesSearch && matchesProduct && matchesCategory;

      card.classList.toggle("hidden", !visible);
      if (visible) count += 1;
    });

    this.emptyState.classList.toggle("hidden", count > 0);
    this.clearButton?.classList.toggle("hidden", !this.hasActiveFilters());
  }

  readURL() {
    const params = new URLSearchParams(window.location.search);
    const q = params.get("q");
    if (q) {
      this.searchQuery = q;
      this.searchInput.value = q;
    }

    this.filterContainers.forEach((container) => {
      const value = params.get(container.dataset.skillsFilter);
      if (value) this.setFilterValue(container, value);
    });
  }

  updateURL() {
    const params = new URLSearchParams();
    if (this.searchQuery.trim()) params.set("q", this.searchQuery.trim());

    this.filterContainers.forEach((container) => {
      const value = container.dataset.skillsFilterValue || "";
      if (value) params.set(container.dataset.skillsFilter, value);
    });

    const newUrl = window.location.pathname + (params.toString() ? "?" + params.toString() : "");
    window.history.replaceState({}, "", newUrl);
  }

  hasActiveFilters() {
    return Boolean(this.searchQuery.trim()) ||
      this.filterContainers.some((c) => c.dataset.skillsFilterValue);
  }
}

document.addEventListener("DOMContentLoaded", () => new SkillsIndex());
