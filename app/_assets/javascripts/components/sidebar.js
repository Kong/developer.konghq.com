class SidebarComponent {
  constructor(container) {
    this.container = container;
    this.buttons = container.querySelectorAll(".nav-button");
    this.links = container.querySelectorAll(".nav-link");
    this.backButton = container.querySelector(".back-button");
    this.init();
  }

  init() {
    this.setActiveLink();
    this.addEventListeners();
    this.setupKeyboardNavigation();
  }

  addEventListeners() {
    this.buttons.forEach((button) => {
      button.addEventListener("click", (e) => this.handleButtonClick(e));
    });

    if (this.backButton) {
      this.backButton.addEventListener("click", () => this.handleBackClick());
    }
  }

  setActiveLink() {
    const currentPath = window.location.pathname;
    let activeLink = null;

    this.links.forEach((link) => {
      const linkPath = new URL(link.href, window.location.origin).pathname;

      if (linkPath === currentPath) {
        activeLink = link;
        link.classList.add("nav-link--active");
      }
    });

    if (activeLink) {
      this.expandParentMenus(activeLink, false);
    }
  }

  expandParentMenus(link, close) {
    let parentSubmenu = link.closest(".nav-submenu");
    while (parentSubmenu) {
      const parentButton = this.container.querySelector(
        `[aria-controls="${parentSubmenu.id}"]`
      );
      if (parentButton) {
        parentButton.setAttribute("aria-expanded", "true");
        parentSubmenu.classList.add("nav-submenu--expanded");
        if (parentButton.classList.contains("nav-button--drilldown")) {
          this.handleDrillDown(parentButton, close);
        }
      }
      parentSubmenu = parentSubmenu.parentElement.closest(".nav-submenu");
    }
  }

  setupKeyboardNavigation() {
    [...this.buttons, ...this.links].forEach((element) => {
      element.addEventListener("keydown", (e) => this.handleKeyDown(e));
    });
  }

  handleButtonClick(event) {
    const button = event.currentTarget;
    const isExpanded = button.getAttribute("aria-expanded") === "true";
    const submenu = document.getElementById(
      button.getAttribute("aria-controls")
    );

    if (!submenu) return;

    if (button.classList.contains("nav-button--drilldown") && !isExpanded) {
      this.handleDrillDown(button);
    } else {
      this.closeOtherSubmenus(button);
      if (isExpanded) {
        this.closeSubmenu(button, submenu);
      } else {
        this.openSubmenu(button, submenu);
      }
    }
  }

  handleDrillDown(button, close) {
    const submenu = document.getElementById(
      button.getAttribute("aria-controls")
    );

    button.disabled = true;
    button.parentElement.classList.add("nav-item--drilldown-parent");

    if (close !== false) {
      this.closeAllSubmenus();
    }
    this.container.classList.add("nav-container--drilled-down");
    submenu.classList.add("active-submenu");
    this.openSubmenu(button, submenu, close);
  }

  handleBackClick() {
    const activeDrillDownMenu = this.container.querySelector(
      ".nav-submenu--drilldown.active-submenu"
    );
    if (activeDrillDownMenu) {
      const button = this.container.querySelector(
        `[aria-controls="${activeDrillDownMenu.id}"]`
      );
      button.disabled = false;
      button.parentElement.classList.remove("nav-item--drilldown-parent");

      this.closeSubmenu(button, activeDrillDownMenu);
      this.container.classList.remove("nav-container--drilled-down");
      activeDrillDownMenu.classList.remove("active-submenu");

      button.focus();
      this.expandParentMenus(button);
    }
  }

  openSubmenu(button, submenu, focus) {
    button.setAttribute("aria-expanded", "true");
    submenu.classList.add("nav-submenu--expanded");

    const activeLink = submenu.querySelector(":scope > .nav-link--active");
    if (activeLink) {
      return;
    }
    const firstItem = submenu.querySelector(".nav-link, .nav-button");
    if (firstItem && focus !== false) {
      setTimeout(() => firstItem.focus(), 150);
    }
  }

  closeSubmenu(button, submenu) {
    submenu.classList.remove("nav-submenu--expanded");
    button.setAttribute("aria-expanded", "false");

    const nestedSubmenus = submenu.querySelectorAll(
      ".nav-submenu.nav-submenu--expanded"
    );
    nestedSubmenus.forEach((nested) => {
      nested.classList.remove("nav-submenu--expanded");
      const nestedButton = document.querySelector(
        `[aria-controls="${nested.id}"]`
      );
      if (nestedButton) {
        nestedButton.setAttribute("aria-expanded", "false");
      }
    });
  }

  closeOtherSubmenus(currentButton) {
    const parentNavList = currentButton.closest(".nav-list");
    if (!parentNavList) return;

    const siblingButtons = parentNavList.querySelectorAll(
      ":scope > .nav-item > .nav-button"
    );

    siblingButtons.forEach((button) => {
      if (
        button !== currentButton &&
        button.getAttribute("aria-expanded") === "true"
      ) {
        const submenu = document.getElementById(
          button.getAttribute("aria-controls")
        );
        if (submenu) {
          this.closeSubmenu(button, submenu);
        }
      }
    });
  }

  handleKeyDown(event) {
    const { key, target } = event;

    switch (key) {
      case "ArrowDown":
        event.preventDefault();
        this.focusNext(target);
        break;
      case "ArrowUp":
        event.preventDefault();
        this.focusPrevious(target);
        break;
      case "ArrowRight":
        if (target.classList.contains("nav-button")) {
          event.preventDefault();
          const isExpanded = target.getAttribute("aria-expanded") === "true";
          if (!isExpanded) {
            target.click();
          }
        }
        break;
      case "ArrowLeft":
        if (target.classList.contains("nav-button")) {
          event.preventDefault();
          const isExpanded = target.getAttribute("aria-expanded") === "true";
          if (isExpanded) {
            target.click();
          } else {
            this.focusParent(target);
          }
        } else {
          this.focusParent(target);
        }
        break;
      case "Escape":
        event.preventDefault();
        this.closeAllSubmenus();
        break;
      case "Home":
        event.preventDefault();
        this.focusFirst();
        break;
      case "End":
        event.preventDefault();
        this.focusLast();
        break;
    }
  }

  focusNext(current) {
    const allItems = this.getVisibleItems();
    const currentIndex = allItems.indexOf(current);
    const nextItem = allItems[currentIndex + 1];
    if (nextItem) nextItem.focus();
  }

  focusPrevious(current) {
    const allItems = this.getVisibleItems();
    const currentIndex = allItems.indexOf(current);
    const prevItem = allItems[currentIndex - 1];
    if (prevItem) prevItem.focus();
  }

  focusParent(current) {
    const parentSubmenu = current.closest(".nav-submenu");
    if (parentSubmenu) {
      const parentButton = document.querySelector(
        `[aria-controls="${parentSubmenu.id}"]`
      );
      if (parentButton) {
        parentButton.focus();
      }
    }
  }

  focusFirst() {
    const firstItem = this.container.querySelector(".nav-link, .nav-button");
    if (firstItem) firstItem.focus();
  }

  focusLast() {
    const allItems = this.getVisibleItems();
    const lastItem = allItems[allItems.length - 1];
    if (lastItem) lastItem.focus();
  }

  getVisibleItems() {
    let container = this.container;
    const activeDrillDownMenu = this.container.querySelector(
      ".nav-submenu--drilldown.nav-submenu--expanded"
    );
    if (activeDrillDownMenu) {
      container = activeDrillDownMenu;
    }
    let items = Array.from(
      container.querySelectorAll(".nav-link, .nav-button")
    ).filter((item) => {
      let parent = item.closest(".nav-submenu");
      if (parent === null) {
        return true;
      }
      if (!parent.classList.contains("nav-submenu--expanded")) {
        return false;
      } else {
        return true;
      }
    });

    if (activeDrillDownMenu) {
      items.unshift(this.backButton);
    }
    return items;
  }

  closeAllSubmenus() {
    const expandedButtons = this.container.querySelectorAll(
      '.nav-button[aria-expanded="true"]'
    );
    expandedButtons.forEach((button) => {
      const submenu = document.getElementById(
        button.getAttribute("aria-controls")
      );
      if (submenu) {
        this.closeSubmenu(button, submenu);
      }
    });

    this.container.classList.remove("drilled-down");
    const activeDrillDownMenus = this.container.querySelectorAll(
      ".nav-submenu--drilldown.active-submenu"
    );
    activeDrillDownMenus.forEach((menu) => {
      menu.classList.remove("active-submenu");
    });
  }
}

export default class Sidebar {
  constructor() {
    const navContainer = document.querySelector(".nav-container");
    if (navContainer) {
      new SidebarComponent(navContainer);
    }
  }
}
