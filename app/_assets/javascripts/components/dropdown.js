class Dropdown {
  constructor(container) {
    this.container = container;
    this.trigger = container.querySelector(".dropdown-trigger");
    this.menu = container.querySelector(".dropdown-menu");
    this.menuItems = container.querySelectorAll('[role="menuitem"]');
    this.isOpen = false;
    this.currentIndex = -1;

    this.init();
  }

  init() {
    this.trigger.addEventListener("click", (e) => this.toggleMenu(e));
    this.trigger.addEventListener("keydown", (e) =>
      this.handleTriggerKeydown(e)
    );

    this.menuItems.forEach((item, index) => {
      item.addEventListener("keydown", (e) =>
        this.handleMenuItemKeydown(e, index)
      );
      item.addEventListener("click", () => this.closeMenu());
    });

    document.addEventListener("click", (e) => {
      if (!this.container.contains(e.target)) {
        this.closeMenu();
      }
    });

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && this.isOpen) {
        this.closeMenu();
        this.trigger.focus();
      }
    });
  }

  toggleMenu(e) {
    e.preventDefault();
    this.isOpen ? this.closeMenu() : this.openMenu();
  }

  openMenu() {
    this.isOpen = true;
    this.currentIndex = -1;

    this.trigger.setAttribute("aria-expanded", "true");
    this.menu.setAttribute("aria-hidden", "false");

    setTimeout(() => {
      this.focusMenuItem(0);
    }, 50);
  }

  closeMenu() {
    this.isOpen = false;
    this.currentIndex = -1;

    this.trigger.setAttribute("aria-expanded", "false");
    this.menu.setAttribute("aria-hidden", "true");
  }

  handleTriggerKeydown(e) {
    switch (e.key) {
      case "Enter":
      case " ":
      case "ArrowDown":
        e.preventDefault();
        this.openMenu();
        break;
      case "ArrowUp":
        e.preventDefault();
        this.openMenu();
        this.focusMenuItem(this.menuItems.length - 1);
        break;
    }
  }

  handleMenuItemKeydown(e, index) {
    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        this.focusMenuItem((index + 1) % this.menuItems.length);
        break;
      case "ArrowUp":
        e.preventDefault();
        this.focusMenuItem(index === 0 ? this.menuItems.length - 1 : index - 1);
        break;

      case "Enter":
      case " ":
        e.preventDefault();
        this.menuItems[index].click();
        break;
      case "Tab":
        this.closeMenu();
        break;
    }
  }

  focusMenuItem(index) {
    if (index >= 0 && index < this.menuItems.length) {
      this.currentIndex = index;
      this.menuItems[index].focus();
    }
  }
}

export default class Dropdowns {
  constructor() {
    document.querySelectorAll(".dropdown-container").forEach((elem) => {
      new Dropdown(elem);
    });
  }
}
