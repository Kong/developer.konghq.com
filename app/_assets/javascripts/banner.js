class Banner {
  constructor(elem) {
    this.banner = elem;
    this.closeButton = this.banner.querySelector(".close-banner");
    this.bannerDataId = this.closeButton.dataset.storageId;

    this.init();
    this.addEventListeners();
  }

  init() {
    const closed = localStorage.getItem(this.bannerDataId);
    if (closed === "closed") {
      this.banner.classList.add("hidden");
    }
  }

  addEventListeners() {
    this.closeButton.addEventListener("click", this.onClose.bind(this));
  }

  onClose() {
    localStorage.setItem(this.bannerDataId, "closed");
    this.banner.classList.remove("opacity-100");
    this.banner.classList.add("opacity-0");
    setTimeout(() => this.banner.classList.add("hidden"), 300);
  }
}

document.addEventListener("DOMContentLoaded", function () {
  const banner = document.getElementById("banner");
  if (banner) {
    new Banner(banner);
  }
});
