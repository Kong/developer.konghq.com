document.querySelectorAll(".custom-code-block").forEach((block) => {
  block.addEventListener("click", (e) => {
    const toggle = e.target.closest(".collapsible-toggle");
    if (!toggle) return;

    const expanded = block.classList.toggle("expanded");

    block.querySelectorAll(".collapsible-toggle").forEach((button) => {
      button.setAttribute("aria-expanded", expanded);
    });
  });
});
