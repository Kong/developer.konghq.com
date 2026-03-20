import { createApp } from "vue";
import LLMDropdown from "~/javascripts/apps/LLMDropdown.vue";

document.querySelectorAll(".llm-dropdown-mount").forEach((el) => {
  const app = createApp(LLMDropdown, {
    mdUrl: el.dataset.mdUrl.replace(/\/$/, "") + ".md",
  });
  app.mount(el);
});
