import { createApp } from "vue";
import SearchApp from "../javascripts/apps/Search.vue";

if (document.getElementById("search-app") !== null) {
  const app = createApp(SearchApp);
  app.mount("#search-app");
}
