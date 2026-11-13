// Opens the "Install agent tools" dialog on skill pages.
// Markup: includes/skills/set_up_agent_dialog.html and info_box/sections/set_up_agent.html.
const TRANSITION_MS = 200;

document.addEventListener("DOMContentLoaded", () => {
  const dialog = document.getElementById("set-up-agent-dialog");
  if (!dialog) return;

  let lastTrigger = null;

  const open = (trigger) => {
    lastTrigger = trigger;
    // Always start on the first tab, not the one the Tabs component remembered.
    const firstTab = dialog.querySelector("[role=tab]");
    if (firstTab) {
      document.dispatchEvent(
        new CustomEvent("tabSelected", { detail: { tabSlug: firstTab.dataset.slug } }),
      );
    }
    dialog.showModal();
    // Force a reflow so the transition runs from the closed state.
    void dialog.offsetWidth;
    dialog.classList.add("is-open");
  };

  const close = () => {
    if (!dialog.open) return;
    dialog.classList.remove("is-open");
    setTimeout(() => {
      dialog.close();
      lastTrigger?.focus();
    }, TRANSITION_MS);
  };

  document.querySelectorAll("[data-set-up-agent-open]").forEach((button) => {
    button.addEventListener("click", () => open(button));
  });

  dialog.querySelectorAll("[data-set-up-agent-close]").forEach((button) => {
    button.addEventListener("click", close);
  });

  // Backdrop click: the click target is the dialog itself, not its content.
  dialog.addEventListener("click", (event) => {
    if (event.target === dialog) close();
  });

  // Esc: animate out instead of closing immediately.
  dialog.addEventListener("cancel", (event) => {
    event.preventDefault();
    close();
  });
});
