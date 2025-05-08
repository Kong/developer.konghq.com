export default class TopNav {
  constructor() {
    this.elem = document.getElementById("top-nav");
    this.mobileMenuOpen = document.getElementById("top-nav-open");
    this.mobileMenuClose = document.getElementById("top-nav-close");
    this.mobileBackButton = document.getElementById("top-nav-back");
    this.allNavBarItems = document.querySelectorAll(".navbar-item");
    this.init();
  }

  init() {
    this.elem.querySelectorAll(".navbar-item__trigger").forEach((item) => {
      item.addEventListener("click", this.onClick.bind(this));
    });
    this.elem.addEventListener("keydown", this.onKeyDown.bind(this));

    document.addEventListener("click", this.onDocumentClick.bind(this));
    document.addEventListener("keydown", this.onDocumentKeyDown.bind(this));

    const triggers = this.elem.querySelectorAll(
      ".navbar-item__trigger, .button"
    );

    triggers.forEach((navBarItemTrigger) => {
      navBarItemTrigger.addEventListener("focus", (elem) => {
        if (!this.isMobileMenuOpened()) {
          this.closeAllMenus();
        }
      });
    });

    this.mobileMenuOpen.addEventListener(
      "click",
      this.openMobileMenu.bind(this)
    );

    this.mobileMenuClose.addEventListener(
      "click",
      this.closeMobileMenu.bind(this)
    );

    this.mobileBackButton.addEventListener(
      "click",
      this.onMobileBackButtonClick.bind(this)
    );
  }

  onClick(event) {
    event.stopPropagation();
    const closestTrigger = event.target.closest(".navbar-item__trigger");

    if (!closestTrigger) {
      this.closeAllMenus();
      return;
    }

    if (!closestTrigger.closest(".navbar-item").getAttribute("aria-haspopup")) {
      return;
    }

    const thisNavBarItem = closestTrigger.closest(".navbar-item");

    this.toggleMenu(closestTrigger);

    this.allNavBarItems.forEach((navBarItem) => {
      if (navBarItem !== thisNavBarItem) {
        this.toggleMenuVisible(navBarItem, false);
      }
    });
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

  onMobileBackButtonClick(event) {
    event.stopPropagation();

    this.allNavBarItems.forEach((item) => {
      item.classList.remove("hidden", "navbar-item--opened");
    });
    this.toggleControls();
  }

  toggleMenu(target) {
    const navBarItem = target.closest(".navbar-item");

    const visible = navBarItem.classList.contains("navbar-item--opened");
    this.toggleMenuVisible(navBarItem, !visible);
    this.toggleControls();
  }

  toggleControls(show) {
    Array.from(this.elem.querySelector(".top-nav__controls").children).forEach(
      (child) => {
        child.classList.toggle("hidden");
      }
    );
  }

  toggleMenuVisible(element, show) {
    const navBarItem = element;
    const menu = navBarItem.querySelector(".navbar-item__menu");

    if (show) {
      navBarItem.classList.add("navbar-item--opened");
      navBarItem.setAttribute("aria-expanded", "true");
      if (this.isMobileMenuOpened()) {
        navBarItem.classList.remove("hidden");
      }
      if (menu) {
        menu.querySelectorAll("a").forEach((link) => {
          link.removeAttribute("tabindex");
        });
      }
    } else {
      navBarItem.classList.remove("navbar-item--opened");
      navBarItem.setAttribute("aria-expanded", "false");

      if (this.isMobileMenuOpened()) {
        if (this.elem.querySelector(".navbar-item--opened")) {
          navBarItem.classList.add("hidden");
        } else {
          navBarItem.classList.remove("hidden");
        }
      }
      if (menu) {
        menu.querySelectorAll("a").forEach((link) => {
          link.setAttribute("tabindex", "-1");
        });
      }
    }
  }

  openMobileMenu(event) {
    event.stopPropagation();
    this.elem.classList.add("top-nav--opened", "duration-500");

    document.body.style.setProperty("overflow", "hidden");
    document.body.style.setProperty("overscroll-behavior", "contain");
  }

  closeMobileMenu(event) {
    event.stopPropagation();

    this.closeAllMenus();
    this.elem.classList.remove("top-nav--opened");
    document.body.style.overflow = "";
    document.body.style.removeProperty("overscoll-behavior");
  }

  isMobileMenuOpened() {
    return this.elem.classList.contains("top-nav--opened");
  }

  closeAllMenus() {
    this.allNavBarItems.forEach((item) => {
      this.toggleMenuVisible(item, false);
    });
  }
}
