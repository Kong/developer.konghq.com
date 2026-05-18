class SkillsIndex {
  constructor() {
    this.searchInput = document.getElementById("skills-search");
    this.skillsGrid = document.getElementById("skills-grid");
    this.emptyState = document.getElementById("skills-empty");
    this.clearButton = document.getElementById("skills-clear-filters");
    this.filterInputs = Array.from(
      document.querySelectorAll("[data-skills-filter]"),
    );

    if (!this.searchInput || !this.skillsGrid || !this.emptyState) return;

    this.cards = Array.from(this.skillsGrid.querySelectorAll('[data-card="skill"]'));
    this.searchQuery = "";
    this.filters = {
      plugin: "",
      product: "",
      category: "",
    };

    this.addEventListeners();
    this.preventCopyNavigation();
    this.readURL();
    this.filterCards();
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

    this.filterInputs.forEach((input) => {
      input.addEventListener("change", () => {
        this.filters[input.dataset.skillsFilter] = input.value;
        this.filterCards();
        this.updateURL();
      });
    });

    this.clearButton?.addEventListener("click", () => {
      this.searchQuery = "";
      this.searchInput.value = "";

      this.filterInputs.forEach((input) => {
        this.filters[input.dataset.skillsFilter] = "";
        input.value = "";
      });

      this.filterCards();
      this.updateURL();
    });
  }

  filterCards() {
    const query = this.searchQuery.toLowerCase().trim();
    const activePlugin = this.filters.plugin;
    const activeProduct = this.filters.product;
    const activeCategory = this.filters.category;
    let count = 0;

    this.cards.forEach((card) => {
      const matchesSearch =
        !query ||
        [
        card.dataset.title,
        card.dataset.description,
        card.dataset.tags,
        card.dataset.plugin,
        card.dataset.products,
        card.dataset.category,
      ]
        .filter(Boolean)
        .join(" ")
        .includes(query);

      const matchesPlugin =
        !activePlugin || card.dataset.pluginSlug === activePlugin;
      const productValues = (card.dataset.productValues || "")
        .split("|")
        .filter(Boolean);
      const matchesProduct =
        !activeProduct || productValues.includes(activeProduct);
      const matchesCategory =
        !activeCategory || card.dataset.categoryValue === activeCategory;
      const visible =
        matchesSearch && matchesPlugin && matchesProduct && matchesCategory;

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

    this.filterInputs.forEach((input) => {
      const value = params.get(input.dataset.skillsFilter);
      if (!value) return;

      this.filters[input.dataset.skillsFilter] = value;
      input.value = value;
    });
  }

  updateURL() {
    const params = new URLSearchParams();
    if (this.searchQuery.trim()) {
      params.set("q", this.searchQuery.trim());
    }

    Object.entries(this.filters).forEach(([key, value]) => {
      if (value) {
        params.set(key, value);
      }
    });

    const newUrl =
      window.location.pathname +
      (params.toString() ? "?" + params.toString() : "");
    window.history.replaceState({}, "", newUrl);
  }

  hasActiveFilters() {
    return (
      Boolean(this.searchQuery.trim()) ||
      Object.values(this.filters).some(Boolean)
    );
  }
}

document.addEventListener("DOMContentLoaded", () => new SkillsIndex());
