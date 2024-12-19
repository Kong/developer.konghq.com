import { createApp } from "vue";
import APISpec from "~/javascripts/apps/APISpec.vue";
import "@kong/spec-renderer-dev/dist/style.css";

if (document.getElementById("api-spec") !== null) {
  const app = createApp(APISpec);
  app.mount("#api-spec");
}
