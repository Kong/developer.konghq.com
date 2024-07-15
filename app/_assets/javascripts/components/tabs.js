class TabsComponent {
  constructor(elem) {
    this.elem = elem;
    this.tablistNode = this.elem.querySelector('[role=tablist]');
    this.activeTabClasses = ['text-blue-600', 'border-blue-600'];
    this.inactiveTabClasses = ['hover:text-gray-600', 'hover:border-gray-600'];

    this.tabs = Array.from(this.tablistNode.querySelectorAll('[role=tab]'));
    this.firstTab = this.tabs[0];
    this.lastTab = this.tabs[this.tabs.length - 1];

    this.tabs.forEach((tab) => {
      tab.addEventListener('keydown', this.onKeydown.bind(this));
      tab.addEventListener('click', this.onClick.bind(this));
    });

    this.setSelectedTab(this.firstTab, false);
  }

  onKeydown(event) {
    const tgt = event.currentTarget;
    let flag = false;

    switch (event.key) {
      case 'ArrowLeft':
        this.setSelectedToPreviousTab(tgt);
        flag = true;
        break;

      case 'ArrowRight':
        this.setSelectedToNextTab(tgt);
        flag = true;
        break;

      case 'Home':
        this.setSelectedTab(this.firstTab);
        flag = true;
        break;

      case 'End':
        this.setSelectedTab(this.lastTab);
        flag = true;
        break;

      default:
        break;
    }
    if (flag) {
      event.stopPropagation();
      event.preventDefault();
    }
  }

  onClick(event) {
    this.setSelectedTab(event.currentTarget);
  }

  setSelectedTab(currentTab, setFocus) {
    if (typeof setFocus !== 'boolean') {
      setFocus = true;
    }
    this.tabs.forEach((tab) => {
      const tabPanel = document.getElementById(tab.getAttribute('aria-controls'));
      if (currentTab === tab) {
        tab.setAttribute('aria-selected', 'true');
        tab.tabIndex = 0;
        tab.classList.add(...this.activeTabClasses);
        tab.classList.remove(...this.inactiveTabClasses);
        tabPanel.classList.remove('hidden');
        if (setFocus) {
          tab.focus();
        }
      } else {
        tab.setAttribute('aria-selected', 'false');
        tab.tabIndex = -1;
        tab.classList.add(...this.inactiveTabClasses);
        tab.classList.remove(...this.activeTabClasses);
        tabPanel.classList.add('hidden');
      }
    });
  }

  setSelectedToPreviousTab(currentTab) {
    if (currentTab === this.firstTab) {
      this.setSelectedTab(this.lastTab);
    } else {
      const index = this.tabs.indexOf(currentTab);
      this.setSelectedTab(this.tabs[index - 1]);
    }
  }

  setSelectedToNextTab(currentTab) {
    if (currentTab === this.lastTab) {
      this.setSelectedTab(this.firstTab);
    } else {
      const index = this.tabs.indexOf(currentTab);
      this.setSelectedTab(this.tabs[index + 1]);
    }
  }
}

export default class Tabs {
  constructor() {
    document.querySelectorAll('.tabs').forEach((elem) => {
      new TabsComponent(elem);
    });
  }
}
