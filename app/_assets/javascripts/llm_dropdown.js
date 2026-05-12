import { createApp } from "vue";
import LLMDropdown from "~/javascripts/apps/LLMDropdown.vue";

document.querySelectorAll(".llm-dropdown-mount").forEach((el) => {
  const tokens = parseInt(el.dataset.tokens, 10);
  const app = createApp(LLMDropdown, {
    mdUrl: el.dataset.mdUrl.replace(/\/$/, "") + ".md",
    tokens: Number.isFinite(tokens) ? tokens : null,
  });
  app.mount(el);
});
