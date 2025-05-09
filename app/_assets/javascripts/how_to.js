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
    if (this.deploymentTopologySwitch) {
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

      this.toggleTopology(this.deploymentTopologySwitch.value);
    } else {
      this.updateTOC();
    }
  }

  onChange(event) {
    localStorage.setItem(this.deploymentToplogyKey, event.target.value);
    this.toggleTopology(event.target.value);
  }

  toggleTopology(topology) {
    this.prerequisites
      .querySelectorAll("[data-deployment-topology]")
      .forEach((item) => {
        this.toggleItem(item, topology);
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
          this.toggleItem(item, topology);
        });
    }

    const event = new Event("accordion:update", { bubbles: true });
    this.prerequisites.dispatchEvent(event);

    if (this.cleanup) {
      this.cleanup.dispatchEvent(event);
    }

    this.updateTOC();
  }

  updateTOC() {
    document.querySelectorAll(".how-to-step--title").forEach((stepTitle) => {
      const id = stepTitle.id;
      const tocItem = document.querySelector(`#toc a[href="#${id}"]`);
      // check if step is visible
      if (stepTitle.offsetParent !== null) {
        tocItem.classList.add("how-to-step");
        tocItem.classList.remove("hidden");
      } else {
        tocItem.classList.remove("how-to-step");
        tocItem.classList.add("hidden");
      }
    });
  }

  toggleItem(item, topology) {
    if (item.dataset.deploymentTopology === topology) {
      item.classList.remove("hidden");
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
