import { createApp } from "vue";
import SearchModalApp from "./apps/SearchModal.vue";

if (document.getElementById("search-modal") !== null) {
  const app = createApp(SearchModalApp);
  app.mount("#search-modal");
}
