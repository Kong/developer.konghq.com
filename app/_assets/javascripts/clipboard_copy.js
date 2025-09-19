document.addEventListener("clipboard-copy", function (event) {
  const button = event.target;
  const tooltip = event.target.previousElementSibling;
  const defaultAriaLabel = button.getAttribute("aria-label");
  const copiedAriaLabel = button.getAttribute("data-copy-feedback");

  button.setAttribute("aria-label", copiedAriaLabel);
  button.classList.add("success");

  tooltip.classList.remove("invisible", "opacity-0");
  setTimeout(() => {
    button.setAttribute("aria-label", defaultAriaLabel);
    button.classList.remove("success");
    tooltip.classList.add("invisible", "opacity-0");
  }, 1800);
});
