document.addEventListener("DOMContentLoaded", function () {
  const isTouchDevice =
    "ontouchstart" in window || navigator.maxTouchPoints > 0;

  const tooltip = document.getElementById("tooltip");
  const elements = document.querySelectorAll("[data-tooltip]");
  let activeElement = null;

  if (isTouchDevice) {
    return;
  }

  function positionTooltip(target) {
    const rect = target.getBoundingClientRect();
    const tooltipRect = tooltip.getBoundingClientRect();

    let left = rect.left + rect.width / 2 - tooltipRect.width / 2;
    let top = rect.top - tooltipRect.height - 8;

    if (left < 0) left = 8;
    if (left + tooltipRect.width > window.innerWidth) {
      left = window.innerWidth - tooltipRect.width - 8;
    }

    if (top < 0) {
      top = rect.bottom + 8;
    }

    tooltip.style.left = left + "px";
    tooltip.style.top = top + "px";
  }

  elements.forEach((el) => {
    el.addEventListener("mouseenter", (e) => {
      const text = el.getAttribute("data-tooltip");
      tooltip.textContent = text;
      tooltip.classList.remove("hidden");
      activeElement = el;
      positionTooltip(el);
    });

    el.addEventListener("mouseleave", () => {
      tooltip.classList.add("hidden");
      activeElement = null;
    });
  });

  window.addEventListener(
    "scroll",
    () => {
      if (activeElement && !tooltip.classList.contains("hidden")) {
        positionTooltip(activeElement);
      }
    },
    true,
  );
});
