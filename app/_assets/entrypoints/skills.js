class SkillsIndex {
  constructor() {
    this.searchInput = document.getElementById("skills-search");
    this.skillsGrid = document.getElementById("skills-grid");
    this.emptyState = document.getElementById("skills-empty");
    this.cards = this.skillsGrid.querySelectorAll('[data-card="skill"]');

    this.searchQuery = "";

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
  }

  filterCards() {
    const query = this.searchQuery.toLowerCase().trim();
    let count = 0;

    this.cards.forEach((card) => {
      const matchesSearch =
        !query ||
        card.dataset.title.includes(query) ||
        card.dataset.description.includes(query);
      card.classList.toggle("hidden", !matchesSearch);
      if (matchesSearch) count++;
    });

    this.emptyState.classList.toggle("hidden", count > 0);
  }

  updateURL() {
    const params = new URLSearchParams();
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
    const q = params.get("q");
    if (q) {
      this.searchQuery = q;
      this.searchInput.value = q;
    }
  }
}

document.addEventListener("DOMContentLoaded", () => new SkillsIndex());
