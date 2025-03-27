class EntityExampleComponent {
  constructor(elem, selectKey) {
    this.elem = elem;
    this.formatSelect = this.elem.querySelector(".select-format");
    this.targetSelect = this.elem.querySelector(".select-target");
    this.formatSelectKey = "entity-example-select-format";

    this.addEventListeners();
    this.initializeSelects();

    document.addEventListener(
      "formatSelected",
      this.onFormatSelected.bind(this)
    );
    document.addEventListener(
      "targetSelected",
      this.onTargetSelected.bind(this)
    );
  }

  initializeSelects() {
    if (this.targetSelect) {
      this.targetSelect.dispatchEvent(new Event("change"));
    } else {
      const targetPanel = this.elem.querySelector(
        ".entity-example-target-panel"
      );
      if (targetPanel) {
        targetPanel.classList.remove("hidden");
      }
      this.elem
        .querySelector(".entity-example-format-panel")
        .classList.remove("hidden");
    }
    if (this.formatSelect) {
      try {
        if (localStorage.getItem(this.formatSelectKey) !== null) {
          const storedOption = localStorage.getItem(this.formatSelectKey);
          if (
            storedOption &&
            [...this.formatSelect.options].some(
              (opt) => opt.value === storedOption
            )
          ) {
            this.formatSelect.value = storedOption;
          }
        }
      } catch (error) {
        console.log(error);
      }
      this.formatSelect.dispatchEvent(new Event("change"));
    }
  }

  addEventListeners() {
    if (this.targetSelect) {
      this.targetSelect.addEventListener(
        "change",
        this.onTargetChange.bind(this)
      );
    }
    if (this.formatSelect) {
      this.formatSelect.addEventListener(
        "change",
        this.onFormatChange.bind(this)
      );
    }
  }

  onFormatChange(event) {
    event.stopPropagation();
    const select = event.currentTarget;

    this.elem
      .querySelectorAll(".entity-example-format-panel")
      .forEach((panel) => {
        if (panel.dataset.format === select.value) {
          panel.classList.remove("hidden");
        } else {
          panel.classList.add("hidden");
        }
      });
    localStorage.setItem(this.formatSelectKey, select.value);
  }

  onTargetChange(event) {
    event.stopPropagation();
    const select = event.currentTarget;

    this.elem
      .querySelectorAll(".entity-example-target-panel")
      .forEach((panel) => {
        if (panel.dataset.target === select.value) {
          panel.classList.remove("hidden");
        } else {
          panel.classList.add("hidden");
        }
      });
  }

  onFormatSelected(event) {
    const { option } = event.detail;
    if (this.formatSelect) {
      const optionElement = this.findOptionForSelect(option, this.formatSelect);

      if (optionElement) {
        this.formatSelect.value = optionElement.value;
        const event = new Event("change", { bubbles: false });
        this.formatSelect.dispatchEvent(event);
      }
    }
  }

  onTargetSelected(event) {
    const { option } = event.detail;
    if (this.targetSelect) {
      const optionElement = this.findOptionForSelect(option, this.targetSelect);

      if (optionElement) {
        this.targetSelect.value = optionElement.value;
        const event = new Event("change", { bubbles: false });
        this.targetSelect.dispatchEvent(event);
      }
    }
  }

  findOptionForSelect(option, selectElement) {
    return Array.from(selectElement.options).find((o) => o.value === option);
  }
}

export default class EntityExample {
  constructor() {
    document.querySelectorAll(".entity-example").forEach((elem) => {
      new EntityExampleComponent(elem);
    });

    // Check if a dropdown query param exists in the URL
    const urlParams = new URLSearchParams(window.location.search);
    const formatOption = urlParams.get("format");
    if (formatOption) {
      this.selectDropdownOption(formatOption, "formatSelected");
    }

    const targetOption = urlParams.get("target");
    if (targetOption) {
      this.selectDropdownOption(targetOption, "targetSelected");
    }
  }

  selectDropdownOption(option, eventName) {
    const event = new CustomEvent(eventName, { detail: { option } });
    document.dispatchEvent(event);
  }
}
