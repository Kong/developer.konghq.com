class ToggleSwitch {
  constructor(elem) {
    this.elem = elem;
    this.inputs = this.elem.querySelectorAll(".switch__input");
    this.slider = this.elem.querySelector(".switch__slider");
    this.addEventListeners();
  }

  addEventListeners() {
    this.inputs.forEach((radio) => {
      radio.addEventListener("change", this.onToggleChange.bind(this));
    });
    this.slider.addEventListener("click", this.onSliderClick.bind(this));
  }

  onToggleChange(event) {
    const selectedValue = event.target.value;
    const changeEvent = new CustomEvent("switch-state-change", {
      detail: { selectedValue },
    });

    document.dispatchEvent(changeEvent);
  }

  onSliderClick() {
    const newValue = Array.from(this.inputs).find((radio) => !radio.checked);
    newValue.checked = true;
    newValue.dispatchEvent(new Event("change", { bubbles: true }));
  }

  updateState(selectedValue) {
    this.inputs.forEach((radio) => {
      radio.checked = radio.value === selectedValue;
    });
  }
}

export default class ToggleSwitchManager {
  constructor() {
    this.deploymentToplogyKey = "deployment-topology-switch";
    this.type = "toggle";
    this.values = ["konnect", "on-prem"];
    this.switches = [];
    this.initialValue = "konnect";

    document.querySelectorAll(".switch").forEach((elem) => {
      this.switches.push(new ToggleSwitch(elem));
    });

    this.topologySwitcherOption = document.querySelector(
      "[data-topology-switcher]",
    );

    this.addEventListeners();
    this.init();
  }

  init() {
    if (this.switches.length > 0) {
      this.setType();
      this.setInitialValue();
    } else {
      const value = document.querySelector("[data-works-on]")?.dataset.worksOn;
      this.setInitialValue(value);
    }
  }

  setInitialValue(value) {
    if (value !== undefined) {
      this.initialValue = value;
    } else {
      if (this.getStoredValue()) {
        this.initialValue = this.getStoredValue();
      }
      if (this.getParamValue()) {
        this.initialValue = this.getParamValue();
      }
      if (this.getURLValue()) {
        this.initialValue = this.getURLValue();
      }
    }

    const initialEvent = new CustomEvent("switch-state-change", {
      detail: { selectedValue: this.initialValue },
    });

    if (this.initialValue !== undefined) {
      document.dispatchEvent(initialEvent);
    }
  }

  setType() {
    if (this.topologySwitcherOption) {
      this.type = this.topologySwitcherOption.dataset.topologySwitcher;
    }
  }

  getURLValue() {
    if (this.type === "page") {
      if (this.values.includes(this.lastURLSegment())) {
        return this.lastURLSegment();
      }
    }
  }

  lastURLSegment() {
    const segments = window.location.pathname.split("/");
    if (!segments[segments.length - 1]) {
      segments.pop();
    }
    return segments[segments.length - 1];
  }

  switchPageTopology(value) {
    if (this.lastURLSegment() !== value) {
      const url = new URL(window.location.href);
      const segments = url.pathname.split("/");
      if (!segments[segments.length - 1]) {
        segments.pop();
      }
      segments[segments.length - 1] = value;
      url.pathname = segments.join("/");
      window.location.href = url.toString();
    }
  }

  getStoredValue() {
    try {
      if (localStorage.getItem(this.deploymentToplogyKey) !== null) {
        const storedValue = localStorage.getItem(this.deploymentToplogyKey);
        if (storedValue && this.values.some((v) => v === storedValue)) {
          return storedValue;
        }
      }
    } catch (error) {
      console.log(error);
    }
  }

  getParamValue() {
    const urlParams = new URLSearchParams(window.location.search);
    const deployment = urlParams.get("deployment");
    if (this.values.includes(deployment)) {
      return deployment;
    }
  }

  addEventListeners() {
    document.addEventListener("switch-state-change", (event) => {
      const { selectedValue } = event.detail;
      localStorage.setItem(this.deploymentToplogyKey, selectedValue);

      if (this.type === "page") {
        this.switchPageTopology(selectedValue);
      }

      if (this.getParamValue() && this.getParamValue() !== selectedValue) {
        const url = new URL(window.location);

        url.searchParams.set("deployment", selectedValue);

        // Don't reload the page
        window.history.pushState({}, "", url);
      }

      this.switches.forEach((instance) => {
        instance.updateState(selectedValue);
      });
    });
  }
}
