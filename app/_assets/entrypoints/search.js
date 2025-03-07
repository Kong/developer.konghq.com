import { createApp } from "vue";
import SearchApp from "../javascripts/apps/Search.vue";
import SearchIndexApp from "../javascripts/apps/SearchIndex.vue";

if (document.getElementById("search-app") !== null) {
  const app = createApp(SearchApp);
  app.mount("#search-app");
} else if (document.getElementById("search-index-app") !== null) {
  const app = createApp(SearchIndexApp);
  app.mount("#search-index-app");
}
