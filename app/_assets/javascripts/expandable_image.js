// Add class="expandable-image" to an <img> to open it enlarged in a modal on click.
document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("img.expandable-image").forEach((img) => {
    const dialog = document.createElement("dialog");
    dialog.className =
      "p-0 border-0 bg-transparent max-w-[95vw] max-h-[95vh] overflow-hidden";

    const enlarged = document.createElement("img");
    enlarged.src = img.src;
    enlarged.alt = img.alt;
    enlarged.className = "block max-w-[95vw] max-h-[95vh] cursor-zoom-out";
    dialog.appendChild(enlarged);
    dialog.addEventListener("click", () => dialog.close());
    document.body.appendChild(dialog);

    const open = () => dialog.showModal();
    img.classList.add("cursor-zoom-in");
    img.setAttribute("role", "button");
    img.setAttribute("tabindex", "0");
    img.addEventListener("click", open);
    img.addEventListener("keydown", (e) => {
      if (e.key === "Enter") open();
    });
  });
});
