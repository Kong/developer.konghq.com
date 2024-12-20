class Hub {
  constructor() {
    this.filters = document.getElementById("filters");
    this.textInput = document.getElementById("plugins-search");
    this.plugins = document.querySelectorAll("[data-card='plugin']");

    this.deploymentTopologies = this.filters.querySelectorAll(
      'input[name="deployment-topology"]'
    );
    this.categories = this.filters.querySelectorAll('input[name="category"]');

    this.deploymentValues = [];
    this.categoryValues = [];

    this.typingTimer;
    this.typeInterval = 400;

    this.addEventListeners();
  }

  addEventListeners() {
    const checkboxes = [...this.deploymentTopologies, ...this.categories];
    checkboxes.forEach((checkbox) => {
      checkbox.addEventListener("change", () => this.onChange());
    });

    this.textInput.addEventListener("keyup", () => {
      clearTimeout(this.typingTimer);

      this.typingTimer = setTimeout(() => {
        this.onChange();
      }, this.typeInterval);
    });
  }

  onChange() {
    this.deploymentValues = this.getValues(this.deploymentTopologies);
    this.categoryValues = this.getValues(this.categories);

    this.filterPlugins();
  }

  getValues(filterGroup) {
    return Array.from(filterGroup)
      .filter((checkbox) => checkbox.checked)
      .map((checkbox) => checkbox.value);
  }

  filterPlugins() {
    this.plugins.forEach((plugin) => {
      const matchesDeploymentTopology = this.matchesFilter(
        plugin,
        this.deploymentTopologies,
        "deploymentTopology"
      );
      const matchesCategory = this.matchesFilter(
        plugin,
        this.categories,
        "category"
      );

      const matchesText = this.matchesQuery(plugin);

      const showPlugin =
        matchesDeploymentTopology && matchesCategory && matchesText;

      plugin.classList.toggle("hidden", !showPlugin);
    });

    this.toggleCategoriesIfEmpty();
  }

  toggleCategoriesIfEmpty() {
    this.categories.forEach((cat) => {
      const category = document.getElementById(cat.value);
      const showCategory = category.querySelectorAll(
        '[data-card="plugin"]:not(.hidden)'
      ).length;

      category.classList.toggle("hidden", !showCategory);
    });
  }

  matchesFilter(plugin, filterGroup, dataAttribute) {
    const checkedValues = Array.from(filterGroup)
      .filter((checkbox) => checkbox.checked)
      .map((checkbox) => checkbox.value);

    const dataValues = plugin.dataset[dataAttribute]?.split(",") || [];
    return (
      checkedValues.length === 0 ||
      checkedValues.some((value) => dataValues.includes(value))
    );
  }

  matchesQuery(plugin) {
    if (this.textInput.value === "") {
      return true;
    } else {
      const query = this.textInput.value.toLowerCase();
      const title = plugin.querySelector("h4").innerText.toLowerCase();
      const aliases = plugin.dataset.search?.split(",") || [];

      return [title, ...aliases].some((string) => string.includes(query));
    }
  }
}

// Initialize the Hub once the DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => new Hub());
