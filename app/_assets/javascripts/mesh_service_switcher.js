class MeshServiceSwitcher {
  static KEY = "mesh-service-support";

  constructor(elem) {
    this.elem = elem;

    const $toggles = this.elem.querySelectorAll(".meshservice");

    // when any checkbox is clicked, sync the storage
    [...$toggles].forEach(($item) =>
      $item.addEventListener("change", (e) =>
        this.set(this.constructor.KEY, e.target.checked)
      )
    );

    // listen for all storage events/syncs, i.e. changes
    window.addEventListener("storage", (e) => {
      if (e.key === this.constructor.KEY) {
        [...$toggles].forEach(($item) => {
          // the $bits we need
          const $checkbox = $item.querySelector('input[type="checkbox"]');
          const $legacy = $item.parentNode.querySelector(
            ".meshservice ~ .custom-code-block:nth-child(2)"
          );
          const $meshService = $item.parentNode.querySelector(
            ".meshservice ~ .custom-code-block:nth-child(3)"
          );

          // get the changed value and update the view
          const enabled = this.get(this.constructor.KEY, e.key);
          $checkbox.checked = enabled;

          (enabled ? $meshService : $legacy).classList.remove("hidden");
          (!enabled ? $meshService : $legacy).classList.add("hidden");
        });
      }
    });

    // fire a fake event to update the view
    window.dispatchEvent(
      new StorageEvent("storage", { key: this.constructor.KEY })
    );
  }

  set(key, value) {
    if (this.get(key) === value) {
      return;
    }
    localStorage.setItem(key, JSON.stringify(value));
    window.dispatchEvent(new StorageEvent("storage", { key: key }));
  }

  get(key, d = null) {
    try {
      const val = localStorage.getItem(key);
      return val !== null ? JSON.parse(val) : d;
    } catch (e) {
      return d;
    }
  }
}

document.querySelectorAll(".meshservice").forEach((elem) => {
  new MeshServiceSwitcher(elem.closest(".tabs"));
});
