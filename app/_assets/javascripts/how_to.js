class HowTo {
  constructor() {
    this.deploymentTopologySwitch = Array.from(
      document.querySelectorAll(".deployment-topology-switch")
    ).find(
      (e) => !!(e.offsetWidth || e.offsetHeight || e.getClientRects().length)
    );
    this.prerequisites = document.querySelector(".prerequisites");
    this.cleanup = document.querySelector(".cleanup");
    this.deploymentToplogyKey = "deployment-topology-switch";

    this.init();
    this.addEventListeners();
  }

  addEventListeners() {
    if (this.deploymentTopologySwitch) {
      this.deploymentTopologySwitch.addEventListener(
        "change",
        this.onChange.bind(this)
      );
    }
  }

  init() {
    if (this.deploymentTopologySwitch.length) {
      try {
        if (localStorage.getItem(this.deploymentToplogyKey) !== null) {
          const storedOption = localStorage.getItem(this.deploymentToplogyKey);
          if (
            storedOption &&
            [...this.deploymentTopologySwitch.options].some(
              (opt) => opt.value === storedOption
            )
          ) {
            this.deploymentTopologySwitch.value = storedOption;
          }
        }
      } catch (error) {
        console.log(error);
      }

      this.toggleTopology(this.deploymentTopologySwitch.value, true);
    }
  }

  onChange(event) {
    localStorage.setItem(this.deploymentToplogyKey, event.target.value);
    this.toggleTopology(event.target.value, true);
  }

  toggleTopology(topology, trigger) {
    this.prerequisites
      .querySelectorAll("[data-deployment-topology]")
      .forEach((item) => {
        let shouldTrigger = trigger;
        if (shouldTrigger && item.ariaExpanded === "true") {
          shouldTrigger = false;
        }
        this.toggleItem(item, topology, shouldTrigger);
      });

    document
      .querySelectorAll(
        ":not(.prerequisites,.cleanup) [data-deployment-topology]"
      )
      .forEach((item) => {
        this.toggleItem(item, topology);
      });

    if (this.cleanup) {
      this.cleanup
        .querySelectorAll("[data-deployment-topology]")
        .forEach((item) => {
          this.toggleItem(item, topology, trigger);
        });
    }
  }

  toggleItem(item, topology, trigger) {
    if (item.dataset.deploymentTopology === topology) {
      item.classList.remove("hidden");
      if (trigger) {
        const accordionTrigger = item.querySelector(".accordion-trigger");
        if (accordionTrigger) {
          accordionTrigger.click();
        }
      }
    } else {
      item.classList.add("hidden");
    }
  }
}

document.addEventListener("DOMContentLoaded", function () {
  if (document.querySelector(".how-to")) {
    new HowTo();
  }
});
