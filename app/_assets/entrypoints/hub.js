class Hub {
  constructor() {
    this.filters = document.getElementById("filters");
    this.plugins = document.querySelectorAll("[data-card='plugin']");

    this.deploymentTopologies = this.filters.querySelectorAll(
      'input[name="deployment-topology"]'
    );
    this.categories = this.filters.querySelectorAll('input[name="category"]');

    this.deploymentValues = [];
    this.categoryValues = [];

    this.addEventListeners();
  }

  addEventListeners() {
    const checkboxes = [...this.deploymentTopologies, ...this.categories];
    checkboxes.forEach((checkbox) => {
      checkbox.addEventListener("change", () => this.onChange());
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
      const matchesDeploymentTopology = this.filterBy(
        plugin,
        this.deploymentTopologies,
        "deploymentTopology"
      );
      const matchesCategory = this.filterBy(
        plugin,
        this.categories,
        "category"
      );

      const showPlugin = matchesDeploymentTopology && matchesCategory;

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

  filterBy(plugin, filterGroup, dataAttribute) {
    const checkedValues = Array.from(filterGroup)
      .filter((checkbox) => checkbox.checked)
      .map((checkbox) => checkbox.value);

    const dataValues = plugin.dataset[dataAttribute]?.split(",") || [];
    return (
      checkedValues.length === 0 ||
      checkedValues.some((value) => dataValues.includes(value))
    );
  }
}

// Initialize the Hub once the DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => new Hub());
