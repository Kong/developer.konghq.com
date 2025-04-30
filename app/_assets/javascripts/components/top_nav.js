export default class TopNav {
  constructor() {
    this.elem = document.getElementById("top-nav");
    this.init();
  }

  init() {
    this.elem.addEventListener("click", this.onClick.bind(this));
    this.elem.addEventListener("keydown", this.onKeyDown.bind(this));

    document.addEventListener("click", this.onDocumentClick.bind(this));
    document.addEventListener("keydown", this.onDocumentKeyDown.bind(this));

    const triggers = this.elem.querySelectorAll(
      ".navbar-item__trigger, .button"
    );
    triggers.forEach((navBarItemTrigger) => {
      navBarItemTrigger.addEventListener("focus", () => {
        this.closeAllMenus();
      });
    });
  }

  onClick(event) {
    event.stopPropagation();
    const closestTrigger = event.target.closest(".navbar-item__trigger");

    if (!closestTrigger) {
      this.closeAllMenus();
      return;
    }

    const thisMenu = closestTrigger
      .closest(".navbar-item")
      .querySelector(".navbar-item__menu");

    const allMenus = this.elem.querySelectorAll(".navbar-item__menu");
    allMenus.forEach((menu) => {
      if (menu !== thisMenu) {
        this.toggleMenuVisible(menu, false);
      }
    });

    this.toggleMenu(closestTrigger);
  }

  onKeyDown(event) {
    if (event.key === "Enter") {
      const closestTrigger = event.target.closest(".navbar-item__trigger");
      if (closestTrigger) {
        this.toggleMenu(closestTrigger);
      }
    }
  }

  onDocumentClick(event) {
    if (!this.elem.contains(event.target)) {
      this.closeAllMenus();
    }
  }

  onDocumentKeyDown(event) {
    if (event.key === "Escape") {
      this.closeAllMenus();
    }
  }

  toggleMenu(target) {
    const menu = target
      .closest(".navbar-item")
      .querySelector(".navbar-item__menu");

    const shouldShow = menu.classList.contains("hidden");
    this.toggleMenuVisible(menu, shouldShow);
  }

  toggleMenuVisible(element, show) {
    const menu = element;
    const navBarItem = element.closest(".navbar-item");
    const triggerIcon = navBarItem.querySelector(".navbar-item__trigger_icon");
    const menuCaret = navBarItem.querySelector(".navbar-item__menu-caret");

    menu.classList.toggle("hidden", !show);

    if (show) {
      navBarItem.setAttribute("aria-expanded", "true");
      triggerIcon.classList.add("rotate-180");
      menuCaret.classList.remove("hidden");
      menu.querySelectorAll("a").forEach((link) => {
        link.removeAttribute("tabindex");
      });
    } else {
      navBarItem.setAttribute("aria-expanded", "false");
      triggerIcon.classList.remove("rotate-180");
      menuCaret.classList.add("hidden");
      menu.querySelectorAll("a").forEach((link) => {
        link.setAttribute("tabindex", "-1");
      });
    }
  }

  closeAllMenus() {
    const allMenus = this.elem.querySelectorAll(".navbar-item__menu");
    allMenus.forEach((menu) => {
      this.toggleMenuVisible(menu, false);
    });
  }
}
