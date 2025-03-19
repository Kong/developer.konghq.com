class HowTo {
  constructor() {
    this.deploymentTopologySwitchs = document.querySelectorAll(
      ".deployment-topology-switch"
    );
    this.prerequisites = document.querySelector(".prerequisites");
    this.cleanup = document.querySelector(".cleanup");

    this.init();
    this.addEventListeners();
  }

  addEventListeners() {
    if (this.deploymentTopologySwitchs) {
      this.deploymentTopologySwitchs.forEach((s) => {
        s.addEventListener("change", this.onChange.bind(this));
      });
    }
  }

  init() {
    if (this.deploymentTopologySwitch) {
      this.toggleTopology(this.deploymentTopologySwitch.value, false);
    }
  }

  onChange(event) {
    this.toggleTopology(event.target.value, true);
  }

  toggleTopology(topology, trigger) {
    this.prerequisites
      .querySelectorAll("[data-deployment-topology]")
      .forEach((item) => {
        this.toggleItem(item, topology, trigger);
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
