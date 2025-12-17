class Hub {
  constructor() {
    this.filters = document.getElementById("filters");
    this.textInput = document.getElementById("plugins-search");
    this.plugins = document.querySelectorAll("[data-card='plugin']");
    this.pluginCards = document.getElementById("plugin-cards");
    this.clearFilters = document.getElementById("clear-filters");
    this.seeResults = document.getElementById("see-results");
    this.toggleFiltersDrawer = document.getElementById("toggle-filters-drawer");
    this.mobilesDrawer = document.querySelector(".mobile-drawer");
    this.areFiltersOpen = false;

    this.deploymentTopologies = this.filters.querySelectorAll(
      'input[name="deployment-topology"]'
    );
    this.tiers = this.filters.querySelectorAll('input[name="tier"]');
    this.categories = this.filters.querySelectorAll('input[name="category"]');
    this.support = this.filters.querySelectorAll('input[name="support"]');
    this.trustedContent = this.filters.querySelectorAll(
      'input[name="trusted-content"]'
    );
    this.phases = this.filters.querySelectorAll('input[name="phase"]');
    this.policyTargets = this.filters.querySelectorAll(
      'input[name="policy-target"]'
    );

    this.deploymentValues = [];
    this.categoryValues = [];
    this.supportValues = [];
    this.trustedContentValues = [];
    this.tierValues = [];
    this.phaseValues = [];
    this.policyTargetValues = [];

    this.typingTimer;
    this.typeInterval = 400;

    this.addEventListeners();
    this.updateFiltersFromURL();
  }

  addEventListeners() {
    const checkboxes = [
      ...this.deploymentTopologies,
      ...this.categories,
      ...this.support,
      ...this.trustedContent,
      ...this.tiers,
      ...this.phases,
      ...this.policyTargets,
    ];
    checkboxes.forEach((checkbox) => {
      checkbox.addEventListener("change", () => this.onChange());
    });

    this.textInput.addEventListener("keyup", () => {
      clearTimeout(this.typingTimer);

      this.typingTimer = setTimeout(() => {
        this.onChange();
      }, this.typeInterval);
    });

    this.textInput.addEventListener("input", () => {
      this.onChange();
    });

    this.clearFilters.addEventListener("click", () => {
      checkboxes.forEach((checkbox) => {
        if (checkbox.checked) {
          checkbox.checked = false;
          checkbox.dispatchEvent(new Event("change", { bubbles: false }));
        }
      });
      this.toggleDrawer();
    });
    this.seeResults.addEventListener("click", () => this.toggleDrawer());

    this.toggleFiltersDrawer.addEventListener("click", () =>
      this.toggleDrawer()
    );
  }

  toggleDrawer() {
    this.areFiltersOpen = !this.areFiltersOpen;
    this.mobilesDrawer.classList.toggle("hidden");
    document.body.classList.toggle("modal-overflow");
  }

  onChange() {
    this.deploymentValues = this.getValues(this.deploymentTopologies);
    this.tierValues = this.getValues(this.tiers);
    this.categoryValues = this.getValues(this.categories);
    this.supportValues = this.getValues(this.support);
    this.trustedContentValues = this.getValues(this.trustedContent);
    this.phaseValues = this.getValues(this.phases);
    this.policyTargetValues = this.getValues(this.policyTargets);

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

      const matchesSupport = this.matchesFilter(
        plugin,
        this.support,
        "support"
      );

      const matchesTrustedContent = this.matchesFilter(
        plugin,
        this.trustedContent,
        "trustedContent"
      );

      const matchesPhases = this.matchesFilter(plugin, this.phases, "phases");

      const matchesPolicyTarget = this.matchesFilter(
        plugin,
        this.policyTargets,
        "policyTarget"
      );

      const matchesTier = this.matchesFilter(plugin, this.tiers, "tier");

      const matchesText = this.matchesQuery(plugin);

      const showPlugin =
        matchesDeploymentTopology &&
        matchesCategory &&
        matchesSupport &&
        matchesTrustedContent &&
        matchesTier &&
        matchesPhases &&
        matchesPolicyTarget &&
        matchesText;

      plugin.classList.toggle("hidden", !showPlugin);
    });

    this.toggleCategoriesIfEmpty();
    this.toggleThirdPartyIfEmpty();
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

  toggleThirdPartyIfEmpty() {
    const thirdParty = document.getElementById("third-party");
    if (thirdParty) {
      const showThirdParty = thirdParty.querySelectorAll(
        '[data-card="plugin"]:not(.hidden)'
      ).length;

      thirdParty.classList.toggle("hidden", !showThirdParty);
    }
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

    params.delete("deployment-topology");
    if (this.deploymentValues.length > 0) {
      this.deploymentValues.forEach((value) =>
        params.append("deployment-topology", value)
      );
    }

    params.delete("category");
    if (this.categoryValues.length > 0) {
      this.categoryValues.forEach((value) => params.append("category", value));
    }

    params.delete("support");
    if (this.supportValues.length > 0) {
      this.supportValues.forEach((value) => params.append("support", value));
    }

    params.delete("trusted-content");
    if (this.trustedContentValues.length > 0) {
      this.trustedContentValues.forEach((value) =>
        params.append("trusted-content", value)
      );
    }

    params.delete("tier");
    if (this.tierValues.length > 0) {
      this.tierValues.forEach((value) => params.append("tier", value));
    }

    if (this.textInput.value) {
      params.set("terms", encodeURIComponent(this.textInput.value));
    } else {
      params.delete("terms");
    }

    params.delete("phase");
    if (this.phaseValues.length > 0) {
      this.phaseValues.forEach((value) => params.append("phase", value));
    }

    params.delete("policy-target");
    if (this.policyTargetValues.length > 0) {
      this.policyTargetValues.forEach((value) =>
        params.append("policy-target", value)
      );
    }

    let newUrl = window.location.pathname;
    if (params.size > 0) {
      newUrl += "?" + params.toString();
    }
    window.history.replaceState({}, "", newUrl);
  }

  updateFiltersFromURL() {
    const params = new URLSearchParams(window.location.search);

    const deploymentValues = params.getAll("deployment-topology") || [];
    this.deploymentTopologies.forEach((checkbox) => {
      checkbox.checked = deploymentValues.includes(checkbox.value);
    });

    const categoryValues = params.getAll("category") || [];
    this.categories.forEach((checkbox) => {
      checkbox.checked = categoryValues.includes(checkbox.value);
    });

    const supportValues = params.getAll("support") || [];
    this.support.forEach((checkbox) => {
      checkbox.checked = supportValues.includes(checkbox.value);
    });

    const trustedContentValues = params.getAll("trusted-content") || [];
    this.trustedContent.forEach((checkbox) => {
      checkbox.checked = trustedContentValues.includes(checkbox.value);
    });

    const tierValues = params.getAll("tier") || [];
    this.tiers.forEach((checkbox) => {
      checkbox.checked = tierValues.includes(checkbox.value);
    });

    const phaseValues = params.getAll("phase") || [];
    this.phases.forEach((checkbox) => {
      checkbox.checked = phaseValues.includes(checkbox.value);
    });

    const policyTargetValues = params.getAll("policy-target") || [];
    this.policyTargets.forEach((checkbox) => {
      checkbox.checked = policyTargetValues.includes(checkbox.value);
    });

    const termsValue = params.get("terms") || "";
    this.textInput.value = decodeURIComponent(termsValue);

    if (
      deploymentValues.length ||
      categoryValues.length ||
      supportValues.length ||
      trustedContentValues.length ||
      tierValues.length ||
      phaseValues.length ||
      policyTargetValues.length ||
      termsValue
    ) {
      this.onChange();
    }
  }
}

// Initialize the Hub once the DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => new Hub());
