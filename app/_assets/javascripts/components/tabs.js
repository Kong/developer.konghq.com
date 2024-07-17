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
    // Listen for the custom event to update tabs
    document.addEventListener('tabSelected', this.onTabSelected.bind(this));

    this.setSelectedTab(this.firstTab, false);
  }

  onKeydown(event) {
    const tgt = event.currentTarget;
    let selectedTab;
    let flag = false;

    switch (event.key) {
      case 'ArrowLeft':
        selectedTab = this.getPreviousTab(tgt)
        flag = true;
        break;

      case 'ArrowRight':
        selectedTab = this.getNextTab(tgt)
        flag = true;
        break;

      case 'Home':
        selectedTab = this.firstTab;
        flag = true;
        break;

      case 'End':
        selectedTab = this.lastTab;
        flag = true;
        break;

      default:
        break;
    }
    if (selectedTab) {
      this.setSelectedTab(selectedTab);
    }

    if (flag) {
      event.stopPropagation();
      event.preventDefault();
      if (selectedTab) {
        this.dispatchTabSelectedEvent(selectedTab.dataset.slug);
      }
    }
  }

  onClick(event) {
    this.setSelectedTab(event.currentTarget);
    this.dispatchTabSelectedEvent(event.currentTarget.dataset.slug);
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
        this.toggleTabClasses(tab, true);
        tabPanel.classList.remove('hidden');
        if (setFocus) {
          tab.focus();
        }
      } else {
        tab.setAttribute('aria-selected', 'false');
        tab.tabIndex = -1;
        this.toggleTabClasses(tab, false);
        tabPanel.classList.add('hidden');
      }
    });
  }

  getPreviousTab(currentTab) {
    if (currentTab === this.firstTab) {
      return this.lastTab;
    } else {
      const index = this.tabs.indexOf(currentTab);
      return this.tabs[index - 1];
    }
  }

  getNextTab(currentTab) {
    if (currentTab === this.lastTab) {
      return this.firstTab;
    } else {
      const index = this.tabs.indexOf(currentTab);
      return this.tabs[index + 1];
    }
  }

  setSelectedTabBySlug(slug, setFocus = true) {
    const tab = this.tabs.find(tab => tab.dataset.slug === slug);
    if (tab) {
      this.setSelectedTab(tab, setFocus);
    }
  }

  dispatchTabSelectedEvent(tabSlug) {
    const event = new CustomEvent('tabSelected', { detail: { tabSlug } });
    document.dispatchEvent(event);
  }

  onTabSelected(event) {
    const { tabSlug } = event.detail;
    this.setSelectedTabBySlug(tabSlug, false);
  }

  toggleTabClasses(tab, isActive) {
    if (isActive) {
      tab.classList.add(...this.activeTabClasses);
      tab.classList.remove(...this.inactiveTabClasses);
    } else {
      tab.classList.add(...this.inactiveTabClasses);
      tab.classList.remove(...this.activeTabClasses);
    }
  }
}

export default class Tabs {
  constructor() {
    document.querySelectorAll('.tabs').forEach((elem) => {
      new TabsComponent(elem);
    });

    // Check if a tab query param exists in the URL
    const urlParams = new URLSearchParams(window.location.search);
    const tabSlug = urlParams.get('tab');
    if (tabSlug) {
      this.selectTabBySlug(tabSlug);
    }
  }

  selectTabBySlug(tabSlug) {
    const event = new CustomEvent('tabSelected', { detail: { tabSlug } });
    document.dispatchEvent(event);
  }
}
