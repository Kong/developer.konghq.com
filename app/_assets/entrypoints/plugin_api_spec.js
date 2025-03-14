import { createApp } from "vue";
import PluginAPISpec from "~/javascripts/apps/PluginAPISpec.vue";
import "@kong/spec-renderer/dist/style.css";

if (document.getElementById("plugin-api-spec") !== null) {
  const app = createApp(PluginAPISpec);
  app.mount("#plugin-api-spec");
}
