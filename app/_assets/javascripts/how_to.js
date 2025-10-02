class HowTo {
  constructor() {
    this.prerequisites = document.querySelector(".prerequisites");
    this.cleanup = document.querySelector(".cleanup");

    this.addEventListeners();
    this.init();
  }

  addEventListeners() {
    document.addEventListener("switch-state-change", this.onChange.bind(this));
  }

  init() {
    this.updateTOC();
  }

  onChange(event) {
    this.toggleTopology(event.detail.selectedValue);
  }

  toggleTopology(topology) {
    if (this.prerequisites) {
      this.prerequisites
        .querySelectorAll("[data-deployment-topology]")
        .forEach((item) => {
          this.toggleItem(item, topology);
        });
    }

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

    if (this.prerequisites) {
      this.prerequisites.dispatchEvent(event);
    }

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
