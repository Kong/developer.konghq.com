// Add class="expandable-image" to an <img> to open it enlarged in a modal on click.
// The image block sets this class when `expandable: true` is in its config.
const TRANSITION_MS = 200;

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("img.expandable-image").forEach((img) => {
    const dialog = document.createElement("dialog");
    dialog.className =
      "expandable-image-dialog p-0 border-0 bg-transparent max-w-[95vw] max-h-[95vh] overflow-hidden";

    const enlarged = document.createElement("img");
    enlarged.src = img.src;
    enlarged.alt = img.alt;
    enlarged.className = "block max-w-[95vw] max-h-[95vh] cursor-zoom-out";
    dialog.appendChild(enlarged);
    document.body.appendChild(dialog);

    const open = () => {
      dialog.showModal();
      // Force a reflow so the transition runs from the closed state.
      void dialog.offsetWidth;
      dialog.classList.add("is-open");
    };

    const close = () => {
      if (!dialog.open) return;
      dialog.classList.remove("is-open");
      setTimeout(() => dialog.close(), TRANSITION_MS);
    };

    dialog.addEventListener("click", close);
    dialog.addEventListener("cancel", (e) => {
      // Esc: animate out instead of closing immediately.
      e.preventDefault();
      close();
    });

    img.classList.add("cursor-zoom-in");
    img.setAttribute("role", "button");
    img.setAttribute("tabindex", "0");
    img.addEventListener("click", open);
    img.addEventListener("keydown", (e) => {
      if (e.key === "Enter") open();
    });
  });
});
