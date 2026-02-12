class Accordion {
  constructor(elem) {
    this.accordion = elem;

    // Specify if there's a default opened item.
    this.defaultItem = this.accordion.dataset.default;

    // Specify if the accordion can have multiple items open at a time,
    // true by default.
    this.multipleItems = true;
    if (this.accordion.dataset.multiple === "false") {
      this.multipleItems = false;
    }

    // Specify if the accordion should have all the items expanded by default.
    this.allExpanded = this.accordion.dataset.allExpanded;

    if (this.allExpanded) {
      if (!this.multipleItems) {
        console.log(
          'Accordion Error: data-all-expanded is valid only if data-multiple="true".',
        );
      }
      if (this.defaultItem) {
        console.log(
          "Accordion Error: data-all-expanded and data-default are mutually exclusive.",
        );
      }
    }

    this.init();
    this.addEventListeners();
  }

  init() {
    this.updateAccordion();
  }

  updateAccordion() {
    const hash = window.location.hash.substring(1);
    let hashItemIndex;
    if (hash) {
      const itemIndex = this.items().findIndex((item) =>
        item.querySelector(`:scope > .accordion-trigger[id="${hash}"]`),
      );
      if (itemIndex !== -1) {
        hashItemIndex = itemIndex;
      }
    }

    this.items().forEach((item, index) => {
      if (hashItemIndex !== undefined && hashItemIndex === index) {
        this.openItem(index);
      } else if (
        this.allExpanded ||
        (hashItemIndex === undefined &&
          this.defaultItem &&
          parseInt(this.defaultItem) === index)
      ) {
        this.openItem(index);
      } else {
        this.closeItem(index);
      }
    });
  }

  toggleItem(index) {
    const item = this.items().at(index);
    if (item.getAttribute("aria-expanded") === "true") {
      this.closeItem(index);
    } else {
      this.openItem(index, true);
    }
  }

  closeItem(index) {
    const item = this.items().at(index);
    item.setAttribute("aria-expanded", "false");
    item.querySelector("span.chevron-icon").classList.remove("rotate-180");

    const panel = item.querySelector(".accordion-panel");
    panel.classList.add("hidden");
    panel.hidden = true;
    panel.setAttribute("aria-hidden", "true");
  }

  openItem(index, scroll) {
    const item = this.items().at(index);
    item.setAttribute("aria-expanded", "true");
    item.querySelector("span.chevron-icon").classList.add("rotate-180");

    const panel = item.querySelector(".accordion-panel");
    panel.classList.remove("hidden");
    panel.hidden = false;
    panel.setAttribute("aria-hidden", "false");

    // Scroll into view after a brief delay to account for content expansion
    if (scroll) {
      setTimeout(() => {
        this.accordion.scrollIntoView({ behavior: "smooth", block: "nearest" });
      }, 50);
    }
  }

  addEventListeners() {
    document.addEventListener("accordion:update", (event) => {
      event.stopPropagation();

      if (event.target === this.accordion) {
        this.updateAccordion();
      }
    });

    this.accordion
      .querySelectorAll(":scope > .accordion-item > .accordion-trigger")
      .forEach((trigger) => {
        trigger.addEventListener("click", this.onItemClick.bind(this));
      });
  }

  onItemClick(event) {
    event.preventDefault();
    event.stopPropagation();

    const accordionItem = event.target.closest(".accordion-item");
    const itemIndex = this.items().indexOf(accordionItem);
    this.toggleItem(itemIndex);

    if (!this.multipleItems) {
      this.items().forEach((item, index) => {
        if (index !== itemIndex) {
          this.closeItem(index);
        }
      });
    }
  }

  items() {
    return Array.from(
      this.accordion.querySelectorAll(":scope > .accordion-item:not(.hidden)"),
    );
  }
}

document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll(".accordion").forEach((accordion) => {
    new Accordion(accordion);
  });
});
