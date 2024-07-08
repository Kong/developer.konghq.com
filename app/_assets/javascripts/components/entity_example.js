class EntityExampleComponent {
  constructor(elem) {
    this.elem = elem;
    this.formatSelect = this.elem.querySelector('.select-format');
    this.targetSelect = this.elem.querySelector('.select-target');

    this.addEventListeners();
    this.initializeSelects();
  }

  initializeSelects() {
    if (this.targetSelect) {
      this.targetSelect.dispatchEvent(new Event('change'));
    } else {
      this.elem.querySelector('.entity-example-format-panel').classList.remove('hidden');
    }
    if (this.formatSelect) {
      this.formatSelect.dispatchEvent(new Event('change'));
    }
  }

  addEventListeners() {
    if (this.targetSelect) {
      this.targetSelect.addEventListener('change', this.selectTarget.bind(this));
    }
    if (this.formatSelect) {
      this.formatSelect.addEventListener('change', this.selectFormat.bind(this));
    }
  }

  selectFormat(event) {
    event.stopPropagation();
    const select = event.currentTarget;

    this.elem.querySelectorAll('.entity-example-format-panel').forEach((panel) => {
      if (panel.dataset.format === select.value) {
        panel.classList.remove('hidden');
      } else {
        panel.classList.add('hidden');
      }
    })
  }

  selectTarget(event) {
    event.stopPropagation();
    const select = event.currentTarget;

    this.elem.querySelectorAll('.entity-example-target-panel').forEach((panel) => {
      if (panel.dataset.target === select.value) {
        panel.classList.remove('hidden');
      } else {
        panel.classList.add('hidden');
      }
    })
  }
}

export default class EntityExample {
  constructor() {
    document.querySelectorAll('.entity-example').forEach((elem) => {
      new EntityExampleComponent(elem);
    });
  }
}
