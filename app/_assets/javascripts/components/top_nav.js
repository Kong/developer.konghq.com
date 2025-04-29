export default class TopNav {
  constructor() {
    this.elem = document.getElementById("top-nav");
    this.init();
  }

  init() {
    this.elem.addEventListener("click", this.onClick.bind(this));
    this.elem.addEventListener("keydown", this.onKeyDown.bind(this));

    const triggers = this.elem.querySelectorAll(
      ".navbar-item__trigger, .button"
    );
    triggers.forEach((navBarItemTrigger) => {
      navBarItemTrigger.addEventListener("focus", () => {
        const allMenus = this.elem.querySelectorAll(".navbar-item__menu");
        allMenus.forEach((menu) => {
          this.toggleMenuVisible(menu, false);
        });
      });
    });
  }

  onClick(event) {
    const closestTrigger = event.target.closest(".navbar-item__trigger");
    if (closestTrigger) {
      this.toggleMenu(event.target);
    }
  }

  onKeyDown(event) {
    if (event.key === "Enter") {
      this.toggleMenu(event.target);
    }
  }

  toggleMenu(target) {
    const menu = target
      .closest(".navbar-item")
      .querySelector(".navbar-item__menu");
    this.toggleMenuVisible(menu, menu.classList.contains("hidden"));
  }

  toggleMenuVisible(element, show) {
    const menu = element;
    const navBarItem = element.closest(".navbar-item");
    const triggerIcon = navBarItem.querySelector(".navbar-item__trigger_icon");
    const menuCaret = navBarItem.querySelector(".navbar-item__menu-caret");
    menu.classList.toggle("hidden", !show);

    if (show) {
      menu.closest(".navbar-item").setAttribute("aria-expanded", true);
      triggerIcon.classList.add("rotate-180");
      menuCaret.classList.remove("hidden");
      menu.querySelectorAll("a").forEach((link) => {
        link.removeAttribute("tabindex");
      });
    } else {
      menu.closest(".navbar-item").setAttribute("aria-expanded", false);
      triggerIcon.classList.remove("rotate-180");
      menuCaret.classList.add("hidden");
      menu.querySelectorAll("a").forEach((link) => {
        link.setAttribute("tabindex", "-1");
      });
    }
  }
}
