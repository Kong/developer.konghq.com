class PluginConfigExampleComponent {
  constructor(elem) {
    this.elem = elem;
    this.exampleSelect = this.elem.querySelector('.select-plugin-config');

    this.addEventListeners();
    this.initializeSelect();
  }

  addEventListeners() {
    this.exampleSelect.addEventListener('change', this.onChange.bind(this));
  }

  initializeSelect() {
    this.exampleSelect.dispatchEvent(new Event('change'));
  }

  onChange(event) {
    event.stopPropagation();
    const select = event.currentTarget;

    this.elem.querySelectorAll('.plugin-config-example-panel').forEach((panel) => {
      if (panel.dataset.slug === select.value) {
        panel.classList.remove('hidden');
      } else {
        panel.classList.add('hidden');
      }
    })
  }
}

export default class PluginConfigExample {
  constructor() {
    document.querySelectorAll('.plugin-config-example').forEach((elem) => {
      new PluginConfigExampleComponent(elem);
    });
  }
}
