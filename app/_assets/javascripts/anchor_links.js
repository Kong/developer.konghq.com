document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll(".link-anchor-icon").forEach((icon) => {
    icon.addEventListener("click", function (event) {
      event.stopPropagation();
    });
  });
});
