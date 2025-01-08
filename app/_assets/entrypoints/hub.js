class Hub {
  constructor() {
    this.filters = document.getElementById("filters");
    this.textInput = document.getElementById("plugins-search");
    this.plugins = document.querySelectorAll("[data-card='plugin']");
    this.pluginCards = document.getElementById("plugin-cards");

    this.deploymentTopologies = this.filters.querySelectorAll(
      'input[name="deployment-topology"]'
    );
    this.categories = this.filters.querySelectorAll('input[name="category"]');

    this.deploymentValues = [];
    this.categoryValues = [];

    this.typingTimer;
    this.typeInterval = 400;

    this.addEventListeners();
    this.updateFiltersFromURL();
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

    this.updateURL();
    this.scrollCardsIntoView();
    this.filterPlugins();
  }

  scrollCardsIntoView() {
    const rect = this.pluginCards.getBoundingClientRect();
    if (rect.top < 0) {
      this.pluginCards.scrollIntoView({ behavior: "smooth" });
    }
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

  updateURL() {
    const params = new URLSearchParams(window.location.search);

    if (this.deploymentValues.length > 0) {
      params.set("deployment-topology", this.deploymentValues.join(","));
    } else {
      params.delete("deployment-topology");
    }

    if (this.categoryValues.length > 0) {
      params.set("category", this.categoryValues.join(","));
    } else {
      params.delete("category");
    }

    if (this.textInput.value) {
      params.set("terms", encodeURIComponent(this.textInput.value));
    } else {
      params.delete("terms");
    }

    let newUrl = window.location.pathname;
    if (params.size > 0) {
      newUrl += "?" + params.toString();
    }
    window.history.replaceState({}, "", newUrl);
  }

  updateFiltersFromURL() {
    const params = new URLSearchParams(window.location.search);

    const deploymentValues =
      params.get("deployment-topology")?.split(",") || [];
    this.deploymentTopologies.forEach((checkbox) => {
      checkbox.checked = deploymentValues.includes(checkbox.value);
    });

    const categoryValues = params.get("category")?.split(",") || [];
    this.categories.forEach((checkbox) => {
      checkbox.checked = categoryValues.includes(checkbox.value);
    });

    const termsValue = params.get("terms") || "";
    this.textInput.value = decodeURIComponent(termsValue);

    if (deploymentValues.length || categoryValues.length || termsValue) {
      this.onChange();
    }
  }
}

// Initialize the Hub once the DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => new Hub());
