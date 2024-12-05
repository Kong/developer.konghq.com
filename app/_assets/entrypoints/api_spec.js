import { createApp } from "vue";
import APISpec from "~/javascripts/apps/APISpec.vue";
import { BindOncePlugin } from "vue-bind-once";
import "@kong/spec-renderer-dev/dist/style.css";

if (document.getElementById("api-spec") !== null) {
  const app = createApp(APISpec);
  app.use(BindOncePlugin);
  app.mount("#api-spec");
}
