class CookbooksIndex {
  constructor() {
    this.heroSearch = document.getElementById("cookbooks-search-hero");
    this.listSearch = document.getElementById("cookbooks-search-list");
    this.heroPills = document.querySelectorAll("#hero-category-pills button");
    this.categoryTabs = document.querySelectorAll("#category-tabs button");
    this.allRecipesSection = document.getElementById("all-recipes-section");
    this.cookbookList = document.getElementById("cookbook-list");
    this.emptyState = document.getElementById("cookbook-empty");
    this.rows = this.cookbookList.querySelectorAll('[data-card="cookbook-row"]');

    this.activeCategory = "all";
    this.searchQuery = "";

    this.addEventListeners();
    this.readURL();
    this.filterList();
  }

  addEventListeners() {
    [this.heroSearch, this.listSearch].forEach((input) => {
      input.addEventListener("input", () => {
        this.searchQuery = input.value;
        if (input === this.heroSearch) this.listSearch.value = input.value;
        else this.heroSearch.value = input.value;
        this.filterList();
        this.updateURL();
      });
    });

    this.heroPills.forEach((pill) => {
      pill.addEventListener("click", () => {
        this.setCategory(pill.dataset.category);
        this.allRecipesSection.scrollIntoView({ behavior: "smooth" });
      });
    });

    this.categoryTabs.forEach((tab) => {
      tab.addEventListener("click", () => {
        this.setCategory(tab.dataset.category);
      });
    });
  }

  setCategory(slug) {
    this.activeCategory = slug;
    this.updateTabsUI();
    this.filterList();
    this.updateURL();
  }

  updateTabsUI() {
    this.categoryTabs.forEach((tab) => {
      tab.classList.toggle(
        "tab-button__horizontal--active",
        tab.dataset.category === this.activeCategory
      );
    });

    this.heroPills.forEach((pill) => {
      const active = pill.dataset.category === this.activeCategory;
      pill.classList.toggle("bg-brand-saturated/20", active);
      pill.classList.toggle("border-brand-saturated/40", active);
    });
  }

  filterList() {
    const query = this.searchQuery.toLowerCase().trim();
    let count = 0;

    this.rows.forEach((row) => {
      const matchesCat =
        this.activeCategory === "all" ||
        row.dataset.category === this.activeCategory;
      const matchesSearch =
        !query ||
        row.dataset.title.includes(query) ||
        row.dataset.description.includes(query);
      const show = matchesCat && matchesSearch;
      row.classList.toggle("hidden", !show);
      if (show) count++;
    });

    this.emptyState.classList.toggle("hidden", count > 0);
  }

  updateURL() {
    const params = new URLSearchParams();
    if (this.activeCategory !== "all") {
      params.set("category", this.activeCategory);
    }
    if (this.searchQuery) {
      params.set("q", this.searchQuery);
    }
    const newUrl =
      window.location.pathname +
      (params.toString() ? "?" + params.toString() : "");
    window.history.replaceState({}, "", newUrl);
  }

  readURL() {
    const params = new URLSearchParams(window.location.search);
    const cat = params.get("category");
    if (cat) this.activeCategory = cat;
    const q = params.get("q");
    if (q) {
      this.searchQuery = q;
      this.heroSearch.value = q;
      this.listSearch.value = q;
    }
    this.updateTabsUI();

    if (cat || q) {
      this.allRecipesSection.scrollIntoView({ behavior: "smooth" });
    }
  }
}

document.addEventListener("DOMContentLoaded", () => new CookbooksIndex());
